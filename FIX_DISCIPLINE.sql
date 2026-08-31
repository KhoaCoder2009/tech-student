-- ============================================================
-- FIX DISCIPLINE - Tạo bảng discipline_categories
-- ============================================================

-- Tạo type nếu chưa có
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'discipline_type') THEN
    CREATE TYPE discipline_type AS ENUM ('add', 'subtract');
  END IF;
END $$;

-- Tạo bảng discipline_categories
CREATE TABLE IF NOT EXISTS discipline_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type discipline_type NOT NULL,
  code text UNIQUE NOT NULL,
  label text NOT NULL,
  default_points numeric(4,1) NOT NULL DEFAULT 2.0,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Xóa dữ liệu cũ và seed lại
DELETE FROM discipline_categories;

-- Seed categories
INSERT INTO discipline_categories (type, code, label, default_points, description) VALUES
  ('add', 'duty_well', 'Trực nhật tốt', 2.0, 'Hoàn thành tốt nhiệm vụ trực nhật'),
  ('add', 'activity', 'Tham gia hoạt động', 3.0, 'Tích cực tham gia hoạt động tập thể'),
  ('add', 'help_class', 'Giúp đỡ tập thể', 2.0, 'Giúp đỡ bạn bè, tập thể lớp'),
  ('add', 'achievement', 'Thành tích', 5.0, 'Đạt thành tích học tập, thể thao, văn nghệ'),
  ('add', 'good_behavior', 'Hành vi tốt', 1.0, 'Có hành vi, thái độ tốt'),
  ('subtract', 'late', 'Đi học muộn', 1.0, 'Đến lớp sau giờ quy định'),
  ('subtract', 'no_uniform', 'Không đồng phục', 2.0, 'Không mặc đồng phục theo quy định'),
  ('subtract', 'no_duty', 'Không trực nhật', 3.0, 'Không thực hiện nhiệm vụ trực nhật'),
  ('subtract', 'violation', 'Vi phạm nội quy', 5.0, 'Vi phạm nội quy lớp, trường'),
  ('subtract', 'disrupt', 'Gây rối', 2.0, 'Gây rối trong lớp học');

-- Tạo bảng discipline_logs nếu chưa có
CREATE TABLE IF NOT EXISTS discipline_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid REFERENCES students(id) ON DELETE CASCADE NOT NULL,
  category_id uuid REFERENCES discipline_categories(id),
  type discipline_type NOT NULL,
  points numeric(4,1) NOT NULL,
  reason text NOT NULL,
  date date NOT NULL DEFAULT current_date,
  recorded_by uuid REFERENCES profiles(id) NOT NULL,
  approved_by uuid REFERENCES profiles(id),
  status text NOT NULL DEFAULT 'approved' CHECK (status IN ('pending','approved','rejected')),
  notes text,
  created_at timestamptz DEFAULT now()
);

-- RLS cho discipline_categories
ALTER TABLE discipline_categories ENABLE ROW LEVEL SECURITY;

-- Policy: mọi người đọc được categories
DROP POLICY IF EXISTS read_discipline_categories ON discipline_categories;
CREATE POLICY read_discipline_categories ON discipline_categories 
FOR SELECT USING (auth.uid() IS NOT NULL);

-- Policy: chỉ admin ghi được
DROP POLICY IF EXISTS admin_write_categories ON discipline_categories;
CREATE POLICY admin_write_categories ON discipline_categories 
FOR ALL USING (current_role_is('admin')) 
WITH CHECK (current_role_is('admin'));

-- RLS cho discipline_logs
ALTER TABLE discipline_logs ENABLE ROW LEVEL SECURITY;

-- Policy: admin toàn quyền
DROP POLICY IF EXISTS admin_full_discipline ON discipline_logs;
CREATE POLICY admin_full_discipline ON discipline_logs 
FOR ALL USING (current_role_is('admin')) 
WITH CHECK (current_role_is('admin'));

-- Function update discipline score (nếu chưa có)
CREATE OR REPLACE FUNCTION update_discipline_score()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Chỉ tính điểm đã approved
  UPDATE students
  SET discipline_score = 100 + (
    SELECT COALESCE(SUM(
      CASE WHEN type = 'add' THEN points ELSE -points END
    ), 0)
    FROM discipline_logs
    WHERE student_id = COALESCE(NEW.student_id, OLD.student_id)
      AND status = 'approved'
  )
  WHERE id = COALESCE(NEW.student_id, OLD.student_id);
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Trigger (xóa cũ nếu có, tạo mới)
DROP TRIGGER IF EXISTS trg_discipline_update_score ON discipline_logs;
CREATE TRIGGER trg_discipline_update_score
AFTER INSERT OR UPDATE OR DELETE ON discipline_logs
FOR EACH ROW EXECUTE FUNCTION update_discipline_score();

-- Kiểm tra kết quả
SELECT 
  'Categories' as table_name,
  COUNT(*) as count
FROM discipline_categories
UNION ALL
SELECT 
  'Add categories',
  COUNT(*)
FROM discipline_categories WHERE type = 'add'
UNION ALL
SELECT 
  'Subtract categories',
  COUNT(*)
FROM discipline_categories WHERE type = 'subtract';

SELECT '✓ DISCIPLINE TABLES READY!' as status;