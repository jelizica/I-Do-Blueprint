# Bifrost with full STDIO MCP server dependencies
# Custom image based on Debian (glibc) for full Python package compatibility
# Supports: kindly, llm-council, pydantic, and all other Python packages
# Includes: Swift toolchain with sourcekit-lsp + mcpls (MCP-to-LSP bridge)
#
# Optimizations applied:
# - Parallel build stages (all builder stages run concurrently)
# - Single merged apt-get block (1 update cycle instead of 2)
# - Cache mounts for npm/uv/pip (faster rebuilds)
# - Layer ordering by change frequency (better cache hits)
# - Pinned infrastructure versions (Node, Swift, uv) for stability
# - Stripped debug symbols from binaries
# - Docker HEALTHCHECK for orchestration
# - OCI labels for image metadata
# - Dependency-first COPY pattern for local MCP servers (source changes don't rebuild deps)
#
# BUILD:
#   docker build -t bifrost-custom .
#   docker build --no-cache -t bifrost-custom .  # Full rebuild

# ============================================
# Stage 1a: Extract Bifrost binary from official image
# ============================================
FROM maximhq/bifrost:v1.4.1 AS bifrost-source

# ============================================
# Stage 1b: Build mcp-prompt-engine from source (no arm64 pre-built available)
# Requires Go 1.24+ per upstream go.mod
# ============================================
FROM golang:1.24-bookworm AS prompt-engine-builder
RUN git clone --depth 1 https://github.com/vasayxtx/mcp-prompt-engine.git /src \
    && cd /src && CGO_ENABLED=0 go build -ldflags="-s -w" -o /mcp-prompt-engine .

# ============================================
# Stage 1c: Build narsil-mcp from source (no pre-built linux-arm64)
# ============================================
FROM rust:1.92-bookworm AS narsil-builder
RUN cargo install narsil-mcp --locked
# Binary will be at /usr/local/cargo/bin/narsil-mcp

# ============================================
# Stage 1d: Build mcpls from source (requires Rust 1.88+)
# ============================================
FROM rust:1.92-bookworm AS mcpls-builder
RUN cargo install mcpls --locked
# Binary will be at /usr/local/cargo/bin/mcpls

# ============================================
# Stage 2: Build final image on Debian for glibc compatibility
# ============================================
FROM debian:bookworm-slim

# OCI Labels for image metadata
LABEL org.opencontainers.image.title="Bifrost MCP Gateway" \
      org.opencontainers.image.description="MCP gateway with full STDIO server support, Swift toolchain, and Python compatibility" \
      org.opencontainers.image.version="1.4.1-custom" \
      org.opencontainers.image.vendor="I Do Blueprint" \
      org.opencontainers.image.source="https://github.com/user/i-do-blueprint" \
      org.opencontainers.image.licenses="MIT"

# Build arguments - pinned infrastructure versions for stability
ARG SWIFT_VERSION=5.10.1
ARG NODE_VERSION=20

# Single merged apt-get block for all system dependencies
# - Base: ca-certificates, curl, git, bash, gnupg
# - Build tools: build-essential, pkg-config, libssl-dev (for native modules)
# - Python: python3, pip, venv, dev headers
# - Browser: chromium (for kindly-web-search headless)
# - Process management: dumb-init (zombie reaping for STDIO MCP servers)
# - Utilities: jq (JSON parsing for health monitor), binutils (strip for binary optimization)
# - Swift deps: libc6-dev, libcurl4, libedit2, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    bash \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    gnupg \
    chromium \
    dumb-init \
    jq \
    binutils \
    netcat-openbsd \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-12-dev \
    libncurses-dev \
    libpython3-dev \
    libsqlite3-0 \
    libstdc++-12-dev \
    libxml2-dev \
    libz3-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Environment variables (consolidated)
ENV KINDLY_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium \
    HOME=/root \
    PATH="/root/.local/bin:/usr/local/bin:/usr/bin:$PATH" \
    APP_DIR=/app/data \
    APP_PORT=8080 \
    APP_HOST=0.0.0.0 \
    LOG_LEVEL=info \
    LOG_STYLE=json

# Install Node.js 20 LTS via NodeSource (required for MCP packages)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Swift toolchain (provides sourcekit-lsp for Swift language intelligence)
# Auto-detects architecture (aarch64 or x86_64)
# Note: x86_64 URLs don't have arch suffix, aarch64 do
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ]; then \
         SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/debian12-aarch64/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-debian12-aarch64.tar.gz"; \
       else \
         SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/debian12/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-debian12.tar.gz"; \
       fi \
    && curl -fsSL "$SWIFT_URL" -o swift.tar.gz \
    && tar xzf swift.tar.gz --strip-components=2 -C /usr \
    && rm swift.tar.gz \
    && swift --version

# Copy binaries from parallel build stages (--link for better layer caching)
# Then strip debug symbols to reduce size (~10-50MB savings)
COPY --link --from=bifrost-source /app /app
COPY --link --from=prompt-engine-builder /mcp-prompt-engine /usr/local/bin/mcp-prompt-engine
COPY --link --from=narsil-builder /usr/local/cargo/bin/narsil-mcp /usr/local/bin/narsil-mcp
COPY --link --from=mcpls-builder /usr/local/cargo/bin/mcpls /usr/local/bin/mcpls
RUN strip --strip-debug /usr/local/bin/mcp-prompt-engine /usr/local/bin/narsil-mcp /usr/local/bin/mcpls 2>/dev/null || true

# Install uv (fast Python package manager - provides uvx command)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install pipx for isolated Python app installs
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --break-system-packages pipx \
    && pipx ensurepath

# ============================================
# Install MCP Servers (latest versions for newest features)
# ============================================

# NPM-based MCP servers (global install with cache mount)
RUN --mount=type=cache,target=/root/.npm \
    npm install -g \
    mcp-adr-analysis-server \
    @swiftzilla/mcp \
    reddit-mcp-buddy \
    mcp-remote \
    code-sentinel-mcp

# empirica-mcp: Epistemic tracking (includes empirica as dependency)
RUN --mount=type=cache,target=/root/.cache/pip \
    pipx install empirica-mcp --include-deps

# Python MCP servers via uv (with cache mount for faster rebuilds)
# - basic-memory: Knowledge management
# - beads-mcp: Issue tracking
# - cheetah-greb: AI-powered code search
# - kindly-web-search: Headless browser web search
# - mcp-proxy: stdio-to-HTTP/SSE bridge for persistent connections
RUN --mount=type=cache,target=/root/.cache/uv \
    uv tool install basic-memory && \
    uv tool install beads-mcp && \
    uv tool install cheetah-greb && \
    uv tool install mcp-proxy && \
    uv tool install git+https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server

# ============================================
# Static files (rarely change - copied early for better caching)
# ============================================

# Copy prompt templates for mcp-prompt-engine
COPY prompts /workspace/prompts

# Copy entrypoint script
COPY scripts/entrypoint.sh /opt/scripts/entrypoint.sh
RUN chmod +x /opt/scripts/entrypoint.sh

# ============================================
# Local MCP Servers (copied from host)
# Optimized for fast rebuilds: copy dependency files first, install, then copy source
# This way source code changes don't invalidate dependency install layers
# ============================================

# Code Guardian - code quality and validation (Node.js)
# Step 1: Copy only package files (cached unless deps change)
COPY code-guardian/package.json code-guardian/package-lock.json /opt/mcp-servers/code-guardian/
RUN --mount=type=cache,target=/root/.npm \
    cd /opt/mcp-servers/code-guardian && \
    npm ci --build-from-source
# Step 2: Copy source (only this layer rebuilds on code changes)
COPY code-guardian /opt/mcp-servers/code-guardian

# Local File Organizer - file organization (Python)
# Step 1: Copy requirements and create venv (cached unless deps change)
COPY local_file_organizer/requirements.txt /opt/mcp-servers/local_file_organizer/
RUN --mount=type=cache,target=/root/.cache/pip \
    cd /opt/mcp-servers/local_file_organizer && \
    python3 -m venv venv && \
    ./venv/bin/pip install --no-cache-dir -r requirements.txt 2>/dev/null || ./venv/bin/pip install --no-cache-dir mcp
# Step 2: Copy source (only this layer rebuilds on code changes)
COPY local_file_organizer /opt/mcp-servers/local_file_organizer

# LLM Council - multi-model deliberation (Python/uv)
# Step 1: Copy dependency files (cached unless deps change)
COPY llm-council/pyproject.toml llm-council/uv.lock /opt/mcp-servers/llm-council/
RUN --mount=type=cache,target=/root/.cache/uv \
    cd /opt/mcp-servers/llm-council && uv sync --frozen --no-install-project
# Step 2: Copy source and install the project (creates entry point scripts)
COPY llm-council /opt/mcp-servers/llm-council
RUN --mount=type=cache,target=/root/.cache/uv \
    cd /opt/mcp-servers/llm-council && uv sync --frozen

# ============================================
# Configure MCP servers & create directories (single layer)
# ============================================
RUN mkdir -p /root/.config/basic-memory /root/.config/mcpls /workspace/prompts /etc/bifrost /app/data /opt/scripts && \
    echo '[config]\ndefault_project_mode = true\ndefault_project = "workspace"' > /root/.config/basic-memory/config.toml && \
    printf '[[lsp_servers]]\nlanguage_id = "swift"\ncommand = "sourcekit-lsp"\nargs = []\nfile_patterns = ["**/*.swift"]\n' > /root/.config/mcpls/mcpls.toml

WORKDIR /workspace

# Expose the gateway port
EXPOSE 8080

# Docker HEALTHCHECK - verifies Bifrost API is responding
# Checks every 30s, times out after 10s, retries 3 times before unhealthy
# Start period of 60s allows for initial startup time
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:${APP_PORT}/api/mcp/clients || exit 1

# Default: start with dumb-init (proper zombie reaping) + entrypoint (health monitor)
# dumb-init ensures STDIO MCP server processes are properly reaped when they exit
# entrypoint.sh runs Bifrost + health monitor that auto-reconnects disconnected servers
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/scripts/entrypoint.sh"]
