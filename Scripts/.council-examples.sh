#!/bin/bash
# Example queries for LLM Council
# Source this file to see examples: source scripts/.council-examples.sh

echo "LLM Council - Example Queries"
echo "=============================="
echo ""

echo "# Architecture Decisions"
echo "council \"Should we use monolithic or microservices architecture?\""
echo "council \"SQLite vs PostgreSQL for local-first macOS app?\""
echo "council \"Event Sourcing vs CRUD for wedding planning app?\""
echo ""

echo "# Technology Choices"
echo "council1 \"Compare React vs Vue vs Svelte for new project\""
echo "council1 \"GraphQL vs REST vs tRPC?\""
echo "council1 \"Tailwind vs styled-components vs CSS Modules?\""
echo ""

echo "# Database Design"
echo "council \"Best approach to multi-tenancy: separate DBs or RLS?\""
echo "council \"Normalization vs denormalization for guest management?\""
echo ""

echo "# Caching Strategies"
echo "council1 \"Redis vs Memcached vs in-memory caching?\""
echo "council \"Cache invalidation strategies for real-time collaboration?\""
echo ""

echo "# Security"
echo "council --timeout=300 \"JWT vs session-based auth for macOS app?\""
echo "council \"Best practices for API key rotation?\""
echo ""

echo "# Performance"
echo "council \"Client-side vs server-side pagination for large datasets?\""
echo "council1 \"Lazy loading vs eager loading for related data?\""
echo ""

echo "# Testing"
echo "council \"Unit tests vs integration tests vs E2E - priority order?\""
echo ""

echo "# Deployment"
echo "council \"Blue-green vs canary vs rolling deployment?\""
echo ""
