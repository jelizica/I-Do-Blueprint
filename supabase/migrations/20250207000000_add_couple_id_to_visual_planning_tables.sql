-- Migration: Add couple_id to Visual Planning Tables for Multi-Tenant Isolation
-- Issue: JES-153 - DB Multi-Tenancy: Add couple_id to Visual Planning Tables
-- Created: 2025-02-07
-- Description: Standardizes tenant scoping across all visual planning tables by adding/renaming
--              couple_id columns, adding proper constraints, and updating RLS policies.

-- ============================================================================
-- PHASE 1: Rename tenant_id to couple_id (5 tables)
-- ============================================================================

-- 1. color_palettes: Rename tenant_id to couple_id
ALTER TABLE color_palettes 
RENAME COLUMN tenant_id TO couple_id;

-- Add FK constraint if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'color_palettes_couple_id_fkey'
  ) THEN
    ALTER TABLE color_palettes
    ADD CONSTRAINT color_palettes_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_color_palettes_couple_id 
ON color_palettes(couple_id);

-- 2. mood_boards: Rename tenant_id to couple_id
ALTER TABLE mood_boards 
RENAME COLUMN tenant_id TO couple_id;

-- Add FK constraint if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'mood_boards_couple_id_fkey'
  ) THEN
    ALTER TABLE mood_boards
    ADD CONSTRAINT mood_boards_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_mood_boards_couple_id 
ON mood_boards(couple_id);

-- 3. style_preferences: Rename tenant_id to couple_id
ALTER TABLE style_preferences 
RENAME COLUMN tenant_id TO couple_id;

-- Add FK constraint if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'style_preferences_couple_id_fkey'
  ) THEN
    ALTER TABLE style_preferences
    ADD CONSTRAINT style_preferences_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_style_preferences_couple_id 
ON style_preferences(couple_id);

-- 4. visual_elements: Rename tenant_id to couple_id
ALTER TABLE visual_elements 
RENAME COLUMN tenant_id TO couple_id;

-- Add FK constraint if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'visual_elements_couple_id_fkey'
  ) THEN
    ALTER TABLE visual_elements
    ADD CONSTRAINT visual_elements_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_visual_elements_couple_id 
ON visual_elements(couple_id);

-- 5. visual_planning_analytics: Rename tenant_id to couple_id
ALTER TABLE visual_planning_analytics 
RENAME COLUMN tenant_id TO couple_id;

-- Add FK constraint if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'visual_planning_analytics_couple_id_fkey'
  ) THEN
    ALTER TABLE visual_planning_analytics
    ADD CONSTRAINT visual_planning_analytics_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_visual_planning_analytics_couple_id 
ON visual_planning_analytics(couple_id);

-- ============================================================================
-- PHASE 2: Add couple_id from palette_id lookup (5 tables)
-- ============================================================================

-- 6. palette_exports: Add couple_id from color_palettes
ALTER TABLE palette_exports 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate couple_id from color_palettes (only if there are rows)
UPDATE palette_exports pe
SET couple_id = cp.couple_id
FROM color_palettes cp
WHERE pe.palette_id = cp.id
  AND pe.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM palette_exports LIMIT 1) THEN
    ALTER TABLE palette_exports ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'palette_exports_couple_id_fkey'
  ) THEN
    ALTER TABLE palette_exports
    ADD CONSTRAINT palette_exports_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_palette_exports_couple_id 
ON palette_exports(couple_id);

-- 7. palette_generations: Add couple_id from color_palettes
ALTER TABLE palette_generations 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate couple_id from color_palettes (only if there are rows)
UPDATE palette_generations pg
SET couple_id = cp.couple_id
FROM color_palettes cp
WHERE pg.palette_id = cp.id
  AND pg.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM palette_generations LIMIT 1) THEN
    ALTER TABLE palette_generations ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'palette_generations_couple_id_fkey'
  ) THEN
    ALTER TABLE palette_generations
    ADD CONSTRAINT palette_generations_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_palette_generations_couple_id 
ON palette_generations(couple_id);

-- 8. palette_shares: Add couple_id from color_palettes (owner's couple_id)
ALTER TABLE palette_shares 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate couple_id from color_palettes (the owner's couple)
UPDATE palette_shares ps
SET couple_id = cp.couple_id
FROM color_palettes cp
WHERE ps.palette_id = cp.id
  AND ps.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM palette_shares LIMIT 1) THEN
    ALTER TABLE palette_shares ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'palette_shares_couple_id_fkey'
  ) THEN
    ALTER TABLE palette_shares
    ADD CONSTRAINT palette_shares_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_palette_shares_couple_id 
ON palette_shares(couple_id);

-- 9. palette_versions: Add couple_id from color_palettes
ALTER TABLE palette_versions 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate couple_id from color_palettes (only if there are rows)
UPDATE palette_versions pv
SET couple_id = cp.couple_id
FROM color_palettes cp
WHERE pv.palette_id = cp.id
  AND pv.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM palette_versions LIMIT 1) THEN
    ALTER TABLE palette_versions ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'palette_versions_couple_id_fkey'
  ) THEN
    ALTER TABLE palette_versions
    ADD CONSTRAINT palette_versions_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_palette_versions_couple_id 
ON palette_versions(couple_id);

-- 10. export_templates: Add couple_id from created_by lookup
ALTER TABLE export_templates 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate couple_id from couple_profiles where created_by matches
UPDATE export_templates et
SET couple_id = cp.id
FROM couple_profiles cp
WHERE et.created_by = cp.id
  AND et.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM export_templates LIMIT 1) THEN
    ALTER TABLE export_templates ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'export_templates_couple_id_fkey'
  ) THEN
    ALTER TABLE export_templates
    ADD CONSTRAINT export_templates_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_export_templates_couple_id 
ON export_templates(couple_id);

-- ============================================================================
-- PHASE 3: Add couple_id to remaining tables
-- ============================================================================

-- 11. visual_planning_shares: Add couple_id (polymorphic relationship)
ALTER TABLE visual_planning_shares 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate from mood_boards when resource_type = 'mood_board'
UPDATE visual_planning_shares vps
SET couple_id = mb.couple_id
FROM mood_boards mb
WHERE vps.resource_type = 'mood_board'
  AND vps.resource_id = mb.id
  AND vps.couple_id IS NULL;

-- Populate from color_palettes when resource_type = 'color_palette'
UPDATE visual_planning_shares vps
SET couple_id = cp.couple_id
FROM color_palettes cp
WHERE vps.resource_type = 'color_palette'
  AND vps.resource_id = cp.id
  AND vps.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM visual_planning_shares LIMIT 1) THEN
    ALTER TABLE visual_planning_shares ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'visual_planning_shares_couple_id_fkey'
  ) THEN
    ALTER TABLE visual_planning_shares
    ADD CONSTRAINT visual_planning_shares_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_visual_planning_shares_couple_id 
ON visual_planning_shares(couple_id);

-- 12. asset_color_extractions: Add couple_id from mood_boards
ALTER TABLE asset_color_extractions 
ADD COLUMN IF NOT EXISTS couple_id UUID;

-- Populate couple_id from mood_boards (only if there are rows)
UPDATE asset_color_extractions ace
SET couple_id = mb.couple_id
FROM mood_boards mb
WHERE ace.mood_board_id = mb.id
  AND ace.couple_id IS NULL;

-- Make NOT NULL after population (only if table has data)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM asset_color_extractions LIMIT 1) THEN
    ALTER TABLE asset_color_extractions ALTER COLUMN couple_id SET NOT NULL;
  END IF;
END $$;

-- Add FK constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'asset_color_extractions_couple_id_fkey'
  ) THEN
    ALTER TABLE asset_color_extractions
    ADD CONSTRAINT asset_color_extractions_couple_id_fkey
    FOREIGN KEY (couple_id) 
    REFERENCES couple_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index
CREATE INDEX IF NOT EXISTS idx_asset_color_extractions_couple_id 
ON asset_color_extractions(couple_id);

-- ============================================================================
-- PHASE 4: Update RLS Policies
-- ============================================================================

-- Helper function to get user's couple_id
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT id FROM public.couple_profiles WHERE id = (SELECT auth.uid());
$$;

-- 1. color_palettes RLS policies
DROP POLICY IF EXISTS "Users can access their color palettes" ON color_palettes;
DROP POLICY IF EXISTS "Users can manage their color palettes" ON color_palettes;

CREATE POLICY "Couples can manage their color palettes"
  ON color_palettes
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 2. mood_boards RLS policies
DROP POLICY IF EXISTS "Users can access their mood boards" ON mood_boards;
DROP POLICY IF EXISTS "Users can manage their mood boards" ON mood_boards;

CREATE POLICY "Couples can manage their mood boards"
  ON mood_boards
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 3. style_preferences RLS policies
DROP POLICY IF EXISTS "Users can access their style preferences" ON style_preferences;
DROP POLICY IF EXISTS "Users can manage their style preferences" ON style_preferences;

CREATE POLICY "Couples can manage their style preferences"
  ON style_preferences
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 4. visual_elements RLS policies
DROP POLICY IF EXISTS "Users can access their visual elements" ON visual_elements;
DROP POLICY IF EXISTS "Users can manage their visual elements" ON visual_elements;

CREATE POLICY "Couples can manage their visual elements"
  ON visual_elements
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 5. visual_planning_analytics RLS policies
DROP POLICY IF EXISTS "Users can access their analytics" ON visual_planning_analytics;
DROP POLICY IF EXISTS "Users can manage their analytics" ON visual_planning_analytics;

CREATE POLICY "Couples can manage their visual planning analytics"
  ON visual_planning_analytics
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 6. palette_exports RLS policies
DROP POLICY IF EXISTS "Users can access their palette exports" ON palette_exports;
DROP POLICY IF EXISTS "Users can manage their palette exports" ON palette_exports;

CREATE POLICY "Couples can manage their palette exports"
  ON palette_exports
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 7. palette_generations RLS policies
DROP POLICY IF EXISTS "Users can access their palette generations" ON palette_generations;
DROP POLICY IF EXISTS "Users can manage their palette generations" ON palette_generations;

CREATE POLICY "Couples can manage their palette generations"
  ON palette_generations
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 8. palette_shares RLS policies
DROP POLICY IF EXISTS "Users can access palette shares" ON palette_shares;
DROP POLICY IF EXISTS "Users can manage palette shares" ON palette_shares;

CREATE POLICY "Couples can manage their palette shares"
  ON palette_shares
  FOR ALL
  USING (couple_id = get_user_couple_id() OR shared_with = (SELECT auth.uid()))
  WITH CHECK (couple_id = get_user_couple_id());

-- 9. palette_versions RLS policies
DROP POLICY IF EXISTS "Users can access their palette versions" ON palette_versions;
DROP POLICY IF EXISTS "Users can manage their palette versions" ON palette_versions;

CREATE POLICY "Couples can manage their palette versions"
  ON palette_versions
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 10. export_templates RLS policies
DROP POLICY IF EXISTS "Users can access their export templates" ON export_templates;
DROP POLICY IF EXISTS "Users can manage their export templates" ON export_templates;

CREATE POLICY "Couples can manage their export templates"
  ON export_templates
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 11. visual_planning_shares RLS policies
DROP POLICY IF EXISTS "Users can access visual planning shares" ON visual_planning_shares;
DROP POLICY IF EXISTS "Users can manage visual planning shares" ON visual_planning_shares;

CREATE POLICY "Couples can manage their visual planning shares"
  ON visual_planning_shares
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- 12. asset_color_extractions RLS policies
DROP POLICY IF EXISTS "Users can access their asset color extractions" ON asset_color_extractions;
DROP POLICY IF EXISTS "Users can manage their asset color extractions" ON asset_color_extractions;

CREATE POLICY "Couples can manage their asset color extractions"
  ON asset_color_extractions
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
