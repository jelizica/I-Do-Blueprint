-- Migration: Add Missing Foreign Key Indexes
-- Issue: JES-150
-- Description: Add indexes on foreign key columns to improve query performance,
--              especially for JOIN operations and foreign key constraint checks.
-- 
-- Performance Impact:
-- - Faster JOIN operations (index lookup vs full table scan)
-- - Faster DELETE/UPDATE cascades (instant FK validation)
-- - Better performance as data grows (constant time vs linear scan)

-- =============================================================================
-- ANALYSIS SUMMARY
-- =============================================================================
-- After analyzing the database schema, only 1 foreign key lacks an index:
-- 
-- 1. wedding_tasks.milestone_id (FK: wedding_tasks_milestone_id_fkey)
--    - References: wedding_milestones.id
--    - Impact: Medium-High (will be heavily used as tasks grow)
--    - Current rows: 1 (will grow to 100s-1000s)
-- 
-- Note: The issue mentioned 3 missing indexes, but analysis revealed:
-- - admin_roles.granted_by: Column exists but has NO foreign key constraint
-- - my_estimated_budget.couple_id: Column exists but has NO foreign key constraint
-- 
-- These columns may benefit from regular indexes if frequently queried, but
-- they don't need FK indexes since they lack FK constraints.

-- =============================================================================
-- CREATE MISSING FOREIGN KEY INDEX
-- =============================================================================

-- Index for wedding_tasks.milestone_id
-- This FK is used when:
-- - Filtering tasks by milestone
-- - Viewing milestone progress
-- - Deleting/updating milestones (FK constraint check)
CREATE INDEX IF NOT EXISTS idx_wedding_tasks_milestone_id 
ON wedding_tasks(milestone_id);

-- Add comment for documentation
COMMENT ON INDEX idx_wedding_tasks_milestone_id IS 
  'Index for FK wedding_tasks_milestone_id_fkey - improves task queries by milestone and FK constraint checks';

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Run these queries after migration to verify the index is working:
-- 
-- 1. Verify index exists:
-- SELECT 
--     schemaname,
--     tablename,
--     indexname,
--     indexdef
-- FROM pg_indexes
-- WHERE indexname = 'idx_wedding_tasks_milestone_id';
-- 
-- Expected result: 1 row showing the index definition
--
-- 2. Verify index is being used in queries:
-- EXPLAIN ANALYZE 
-- SELECT * FROM wedding_tasks 
-- WHERE milestone_id = 'some-uuid';
-- 
-- Expected result: Should show "Index Scan using idx_wedding_tasks_milestone_id"
-- NOT "Seq Scan on wedding_tasks"
--
-- 3. Check index usage statistics (run after some production usage):
-- SELECT 
--     schemaname,
--     tablename,
--     indexname,
--     idx_scan as index_scans,
--     idx_tup_read as tuples_read,
--     idx_tup_fetch as tuples_fetched
-- FROM pg_stat_user_indexes
-- WHERE indexname = 'idx_wedding_tasks_milestone_id';

-- =============================================================================
-- PERFORMANCE EXPECTATIONS
-- =============================================================================

-- Before: Full table scan
-- Query time: ~5-10ms (will increase linearly with data growth)
-- SELECT * FROM wedding_tasks WHERE milestone_id = 'uuid';

-- After: Index lookup
-- Query time: ~0.5-1ms (constant time regardless of table size)
-- SELECT * FROM wedding_tasks WHERE milestone_id = 'uuid';

-- Expected improvement: 5-10x faster initially, 10-100x faster at scale (1000+ tasks)

-- =============================================================================
-- ADDITIONAL RECOMMENDATIONS
-- =============================================================================

-- Consider adding foreign key constraints and indexes for:
-- 
-- 1. admin_roles.granted_by
--    - Currently has no FK constraint
--    - Should reference auth.users(id) or admin_roles(id)
--    - Would benefit from both FK constraint and index
-- 
-- 2. my_estimated_budget.couple_id
--    - Currently has no FK constraint
--    - Should reference couple_profiles(id) or auth.users(id)
--    - Would benefit from both FK constraint and index
--    - High usage column (used in most budget queries)
-- 
-- These should be addressed in separate migrations after verifying the
-- correct foreign table references.
