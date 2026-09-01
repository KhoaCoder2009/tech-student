-- ============================================================
-- FIX: Add date_of_birth column to students table
-- ============================================================

-- Add date_of_birth column if not exists
ALTER TABLE students 
ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add comment
COMMENT ON COLUMN students.date_of_birth IS 'Ngày sinh của học sinh';

-- ============================================================
-- NOTE: Run this SQL in Supabase SQL Editor
-- ============================================================
