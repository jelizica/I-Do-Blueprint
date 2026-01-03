---
title: Project Automation Scripts Reference
type: note
permalink: ai-tools/shell-reference/scripts-reference
---

# Project Automation Scripts Reference

This document provides a reference for the project automation scripts used in the "I Do Blueprint" project.

## generate-diagrams.sh

*   **Location**: `./scripts/generate-diagrams.sh`
*   **Purpose**: Generate architecture diagrams from Structurizr DSL.
*   **Requires**: `structurizr-cli` (install via `brew install structurizr-cli`)
*   **Input**: `docs/architecture/workspace.dsl`
*   **Output**: `docs/architecture/exports/*.puml` (PlantUML format)
*   **Usage**: `./scripts/generate-diagrams.sh`

## security-check.sh

*   **Location**: `./scripts/security-check.sh`
*   **Purpose**: Pre-commit security checks.
*   **Checks**:
    *   .env files not staged
    *   Config.plist not committed
    *   No hardcoded secrets in Swift files
    *   No service_role keys
    *   .gitignore has critical entries
*   **Usage**: Run before commits or in git hooks.

## verify-tooling.sh

*   **Location**: `./scripts/verify-tooling.sh`
*   **Purpose**: Verify required tools are installed and authenticated.
*   **Checks**:
    *   GitHub CLI (`gh`) authentication
    *   Xcode Command Line Tools
    *   Supabase CLI authentication
    *   Swift installation
*   **Usage**: `./scripts/verify-tooling.sh`