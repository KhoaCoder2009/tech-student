-- ================================================================
-- TECH-STUDENT: QUICK SETUP WITH DEMO DATA
-- Chạy script này trong Supabase SQL Editor để setup từ đầu
-- ================================================================

-- 1. CREATE EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. CREATE ENUM TYPE
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin','teacher','student');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 3. CREATE TABLES
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'student',
  full_name text NOT NULL,
  email text,
  avatar_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS classes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL UNIQUE,
  school_year text,
  gvcn_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS groups (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  color text DEFAULT '#4f6df5',
  class_id uuid REFERENCES classes(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS positions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  label text NOT NULL UNIQUE,
  scope text DEFAULT 'class',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS students (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  student_code text UNIQUE,
  gender text CHECK (gender IN ('Nam','Nữ')),
  dob date,
  class_id uuid REFERENCES classes(id),
  group_id uuid REFERENCES groups(id),
  discipline_score integer DEFAULT 100,
  attendance_rate numeric(5,2) DEFAULT 100.00,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS student_positions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id uuid REFERENCES students(id) ON DELETE CASCADE,
  position_id uuid REFERENCES positions(id) ON DELETE CASCADE,
  group_id uuid REFERENCES groups(id),
  assigned_at timestamptz DEFAULT now(),
  UNIQUE(student_id, position_id, group_id)
);

CREATE TABLE IF NOT EXISTS announcements (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  content text,
  class_id uuid REFERENCES classes(id) ON DELETE CASCADE,
  created_by uuid REFERENCES auth.users(id),
  is_pinned boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discipline_categories (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  type text CHECK (type IN ('bonus','penalty')),
  points integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discipline_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id uuid REFERENCES students(id) ON DELETE CASCADE,
  category_id uuid REFERENCES discipline_categories(id),
  reason text,
  points integer NOT NULL,
  logged_by uuid REFERENCES auth.users(id),
  logged_at timestamptz DEFAULT now()
);

-- 4. CREATE RLS HELPER FUNCTION
CREATE OR REPLACE FUNCTION current_role_is(check_role user_role)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_role user_role;
BEGIN
  SELECT role INTO v_role FROM profiles WHERE id = auth.uid() AND is_active = true;
  RETURN v_role = check_role;
END;
$$;

-- 5. ENABLE RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_logs ENABLE ROW LEVEL SECURITY;

-- 6. CREATE RLS POLICIES
-- Profiles
DROP POLICY IF EXISTS self_read_profile ON profiles;
DROP POLICY IF EXISTS admin_full_profiles ON profiles;
CREATE POLICY self_read_profile ON profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY admin_full_profiles ON profiles FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- Classes
DROP POLICY IF EXISTS read_classes ON classes;
DROP POLICY IF EXISTS admin_write_classes ON classes;
CREATE POLICY read_classes ON classes FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_classes ON classes FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- Groups
DROP POLICY IF EXISTS read_groups ON groups;
DROP POLICY IF EXISTS admin_write_groups ON groups;
CREATE POLICY read_groups ON groups FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_groups ON groups FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- Positions
DROP POLICY IF EXISTS read_positions ON positions;
DROP POLICY IF EXISTS admin_write_positions ON positions;
CREATE POLICY read_positions ON positions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_positions ON positions FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- Students
DROP POLICY IF EXISTS admin_full_students ON students;
DROP POLICY IF EXISTS students_select_policy ON students;
DROP POLICY IF EXISTS student_update_self ON students;
CREATE POLICY admin_full_students ON students FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));
CREATE POLICY students_select_policy ON students FOR SELECT
  USING (current_role_is('student') OR current_role_is('teacher') OR current_role_is('admin'));
CREATE POLICY student_update_self ON students FOR UPDATE
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Student Positions
DROP POLICY IF EXISTS read_student_positions ON student_positions;
DROP POLICY IF EXISTS admin_write_positions ON student_positions;
CREATE POLICY read_student_positions ON student_positions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_positions ON student_positions FOR ALL
  USING (current_role_is('admin') OR current_role_is('teacher'));

-- Announcements
DROP POLICY IF EXISTS read_announcements ON announcements;
DROP POLICY IF EXISTS create_announcements ON announcements;
DROP POLICY IF EXISTS update_announcements ON announcements;
DROP POLICY IF EXISTS delete_announcements ON announcements;
CREATE POLICY read_announcements ON announcements FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY create_announcements ON announcements FOR INSERT
  WITH CHECK (created_by = auth.uid());
CREATE POLICY update_announcements ON announcements FOR UPDATE
  USING (created_by = auth.uid() OR current_role_is('admin'));
CREATE POLICY delete_announcements ON announcements FOR DELETE
  USING (created_by = auth.uid() OR current_role_is('admin'));

-- Discipline Categories
DROP POLICY IF EXISTS read_categories ON discipline_categories;
DROP POLICY IF EXISTS admin_write_categories ON discipline_categories;
CREATE POLICY read_categories ON discipline_categories FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_categories ON discipline_categories FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- Discipline Logs
DROP POLICY IF EXISTS read_discipline_logs ON discipline_logs;
DROP POLICY IF EXISTS admin_write_logs ON discipline_logs;
CREATE POLICY read_discipline_logs ON discipline_logs FOR SELECT
  USING (student_id = auth.uid() OR current_role_is('admin') OR current_role_is('teacher'));
CREATE POLICY admin_write_logs ON discipline_logs FOR ALL
  USING (current_role_is('admin') OR current_role_is('teacher'));

-- 7. INSERT DEMO DATA
-- Class
INSERT INTO classes (id, name, school_year) VALUES
  ('11111111-1111-1111-1111-111111111111', '12A2', '2024-2025')
ON CONFLICT (name) DO NOTHING;

-- Groups
INSERT INTO groups (id, name, color, class_id) VALUES
  ('22222222-2222-2222-2222-222222222221', 'Tổ 1', '#4f6df5', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222', 'Tổ 2', '#22c9a8', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222223', 'Tổ 3', '#ff6b6b', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222224', 'Tổ 4', '#ffa726', '11111111-1111-1111-1111-111111111111')
ON CONFLICT DO NOTHING;

-- Positions
INSERT INTO positions (label, scope) VALUES
  ('Lớp trưởng', 'class'),
  ('Lớp phó', 'class'),
  ('Bí thư', 'class'),
  ('Phó bí thư', 'class'),
  ('Phó học tập', 'class'),
  ('Phó lao động', 'class'),
  ('Tổ trưởng', 'group'),
  ('Tổ phó', 'group'),
  ('Thành viên', 'group')
ON CONFLICT (label) DO NOTHING;

-- Discipline Categories
INSERT INTO discipline_categories (name, type, points) VALUES
  ('Đi học đúng giờ', 'bonus', 5),
  ('Tham gia hoạt động tích cực', 'bonus', 10),
  ('Giúp đỡ bạn bè', 'bonus', 5),
  ('Đi muộn', 'penalty', -5),
  ('Vắng không phép', 'penalty', -10),
  ('Không làm bài tập', 'penalty', -3),
  ('Vi phạm nội quy', 'penalty', -15)
ON CONFLICT DO NOTHING;

-- ================================================================
-- HƯỚNG DẪN TẠO TÀI KHOẢN
-- ================================================================
-- Sau khi chạy script này, vào Supabase Dashboard:
-- 1. Authentication → Users → Add User
-- 2. Tạo tài khoản với email: admin@techstudent.local, password: admin123
-- 3. Copy User ID
-- 4. Chạy query này (thay YOUR_USER_ID):
--
-- INSERT INTO profiles (id, role, full_name, email, is_active) VALUES
--   ('YOUR_USER_ID', 'admin', 'Admin Tech-Student', 'admin@techstudent.local', true);
--
-- 5. Đăng nhập tại login.html với:
--    Username: admin
--    Password: admin123
-- ================================================================

COMMIT;
