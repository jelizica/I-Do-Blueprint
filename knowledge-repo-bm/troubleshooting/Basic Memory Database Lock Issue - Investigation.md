---
title: Basic Memory Database Lock Issue - Investigation
type: note
permalink: troubleshooting/basic-memory-database-lock-issue-investigation
tags:
- basic-memory
- sqlite
- database-lock
- mcp
- troubleshooting
---

# Basic Memory Database Lock Issue - Investigation

## Problem
Basic Memory MCP operations fail with `sqlite3.OperationalError: database is locked` when attempting write operations.

## Root Cause
Multiple Basic Memory MCP server instances are running simultaneously, all holding open file handles to the same SQLite database at `/Users/jessicaclark/.basic-memory/memory.db`.

### Evidence
Running `lsof /Users/jessicaclark/.basic-memory/memory.db` shows **20+ different Python processes** with multiple file descriptors each holding the database open.

Process IDs observed:
- 5672, 5673 (basic-memory mcp)
- 17033, 17035
- 23061, 23285, 23287
- 41986, 41988
- 61938, 61939
- 63974
- 66754, 66755, 66756, 66766
- 83340, 84467, 87349, 90354
- 92518

## Why This Happens
1. Each Claude Desktop window/session spawns its own MCP server processes
2. Basic Memory uses SQLite which has limited concurrent write support
3. WAL mode is enabled (evidenced by `.db-shm` and `.db-wal` files) but still has write contention
4. Multiple sessions trying to write simultaneously causes lock contention

## Workarounds

### Immediate
- **Retry operations**: Read operations usually succeed; write operations may need retries
- **Wait and retry**: The lock is usually temporary; waiting a few seconds often resolves it
- **Close other Claude windows**: Reduces the number of competing processes

### Long-term Solutions
1. **Single MCP instance**: Configure Claude to share a single Basic Memory instance
2. **Database timeout**: Increase SQLite busy timeout in Basic Memory configuration
3. **Connection pooling**: Use a connection pool with proper locking
4. **Alternative backend**: Consider PostgreSQL or other multi-writer databases

## Observations
- Read operations (`recent_activity`, `read_note`, `search_notes`) usually succeed
- Write operations (`write_note`, `edit_note`) are more likely to fail
- The lock is intermittent - retrying often works

## Related
- relates_to [[Basic Memory MCP Configuration]]
- relates_to [[MCP Tools Overview]]
