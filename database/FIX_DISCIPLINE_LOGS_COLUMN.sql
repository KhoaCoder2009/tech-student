-- ============================================================
-- FIX DISCIPLINE_LOGS TABLE - Add missing columns
-- ============================================================

-- Add violation_type column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'discipline_logs' 
    AND column_name = 'violation_type'
  ) THEN
    ALTER TABLE discipline_logs 
    ADD COLUMN violation_type TEXT NOT NULL DEFAULT 'Vi phạm chung';
  END IF;
END $$;

-- Add points_deducted column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'discipline_logs' 
    AND column_name = 'points_deducted'
  ) THEN
    ALTER TABLE discipline_logs 
    ADD COLUMN points_deducted NUMERIC(5,1) NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Add description column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'discipline_logs' 
    AND column_name = 'description'
  ) THEN
    ALTER TABLE discipline_logs 
    ADD COLUMN description TEXT;
  END IF;
END $$;

-- Add created_by column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'discipline_logs' 
    AND column_name = 'created_by'
  ) THEN
    ALTER TABLE discipline_logs 
    ADD COLUMN created_by UUID REFERENCES profiles(id);
  END IF;
END $$;

-- Verification
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'discipline_logs'
ORDER BY ordinal_position;

-- ============================================================
-- NOTES
-- ============================================================
-- 
-- This migration adds missing columns to discipline_logs table:
-- - violation_type: Type of violation (required)
-- - points_deducted: How many points deducted (default 0)
-- - description: Optional description
-- - created_by: Who created the log
-- 
-- ============================================================
