-- ============================================================
-- ADD NOTIFICATION READ STATUS
-- Track which announcements each user has read
-- ============================================================

-- Create table to track read status
CREATE TABLE IF NOT EXISTS announcement_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID REFERENCES announcements(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  read_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(announcement_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_announcement_reads_user ON announcement_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement ON announcement_reads(announcement_id);

-- Enable RLS
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS read_own_announcement_reads ON announcement_reads;
DROP POLICY IF EXISTS insert_own_announcement_reads ON announcement_reads;

CREATE POLICY read_own_announcement_reads ON announcement_reads 
  FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY insert_own_announcement_reads ON announcement_reads 
  FOR INSERT 
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- NOTES
-- ============================================================
-- 
-- This table tracks which announcements each user has read
-- 
-- Usage:
-- - When user views announcement → INSERT into announcement_reads
-- - Count unread: SELECT COUNT(*) FROM announcements 
--                 WHERE NOT EXISTS (SELECT 1 FROM announcement_reads 
--                                  WHERE announcement_id = announcements.id 
--                                  AND user_id = auth.uid())
-- 
-- ============================================================
