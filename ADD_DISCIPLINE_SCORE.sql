-- ============================================================
-- ADD DISCIPLINE SCORE COLUMN
-- Thêm cột tổng điểm nề nếp cho học sinh
-- ============================================================

-- Thêm cột discipline_score vào bảng students
ALTER TABLE students 
ADD COLUMN IF NOT EXISTS discipline_score numeric(4,1) DEFAULT 100 CHECK (discipline_score >= 0 AND discipline_score <= 100);

-- Thêm index
CREATE INDEX IF NOT EXISTS idx_students_discipline_score ON students(discipline_score);

-- Comment
COMMENT ON COLUMN students.discipline_score IS 'Tổng điểm nề nếp (0-100, mặc định 100)';

-- Update students hiện có về 100 điểm
UPDATE students 
SET discipline_score = 100 
WHERE discipline_score IS NULL;

-- Kiểm tra
DO $$
BEGIN
  RAISE NOTICE '✓ Đã thêm cột discipline_score vào bảng students';
  RAISE NOTICE '  Tất cả học sinh được khởi tạo 100 điểm';
END $$;

-- Test query
SELECT 
  student_code,
  p.full_name,
  discipline_score
FROM students s
JOIN profiles p ON p.id = s.id
ORDER BY student_code
LIMIT 5;
