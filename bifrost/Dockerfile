# Bifrost with full STDIO MCP server dependencies
# Custom image with Node.js, Python, Rust tools for MCP servers

FROM maximhq/bifrost:v1.4.0-prerelease7

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11+ and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager - provides uvx command)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install pipx for isolated Python app installs
RUN pip3 install --break-system-packages pipx \
    && pipx ensurepath
ENV PATH="/root/.local/bin:$PATH"

# Install Rust toolchain (for narsil-mcp)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# ============================================
# Install MCP Servers
# ============================================

# NPM-based MCP servers (global install)
RUN npm install -g \
    mcp-adr-analysis-server \
    reddit-mcp-buddy \
    mcp-remote

# Python MCP servers via pipx (isolated environments)
# greb-mcp: Code search - installed via cheetah-greb package
RUN pipx install cheetah-greb

# empirica-mcp: Epistemic tracking
RUN pipx install empirica-mcp

# Rust MCP servers via cargo
# narsil-mcp: Code intelligence server with call graphs, LSP, git
RUN cargo install narsil-mcp

# ============================================
# Pre-cache uvx packages (optional, speeds up first run)
# These are run via uvx at runtime but we can pre-download
# ============================================
RUN uv tool install basic-memory || true
RUN uv tool install beads-mcp || true

# ============================================
# Setup workspace
# ============================================

WORKDIR /workspace

# Create config directory
RUN mkdir -p /etc/bifrost

# Expose the gateway port
EXPOSE 8080

# Environment setup
ENV HOME=/root
ENV PATH="/root/.local/bin:/root/.cargo/bin:/usr/local/bin:$PATH"

# Note: config.json should be mounted at runtime or copied during build
# CMD ["bifrost", "--config", "/etc/bifrost/config.json"]

# Default: start Bifrost (config can be passed via env or volume mount)
CMD ["bifrost"]
