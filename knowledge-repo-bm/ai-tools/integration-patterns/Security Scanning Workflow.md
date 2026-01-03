---
title: Security Scanning Workflow
type: note
permalink: ai-tools/integration-patterns/security-workflow
---

# Security Scanning Workflow

This document outlines the recommended workflow for security scanning in the "I Do Blueprint" project.

## Daily

*   Run a quick scan of your MCP servers using `mcpscan`.

## Before Commits

*   Run `swiftscan .` to scan your Swift code for security vulnerabilities.

## Weekly

*   Run a full security scan using Semgrep: `semgrep --config p/swift --config p/secrets .`
*   Run a deep analysis of your MCP servers using `mcpscan-all`.