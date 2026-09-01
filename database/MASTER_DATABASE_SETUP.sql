-- ============================================================
-- TECH-STUDENT · MASTER DATABASE SETUP
-- File duy nhất để setup toàn bộ database từ đầu
-- Chạy file này trong Supabase SQL Editor trên project mới
-- ============================================================
-- Version: 1.0
-- Last Updated: 2026-08-31
-- Description: Complete database schema, RLS policies, seed data, and account creation
-- ============================================================

-- ============================================================
-- PART 1: CORE SCHEMA
-- ============================================================

-- Drop existing types if needed (for clean reinstall)
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin','teacher','student');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- ---------- Danh mục lõi ----------
CREATE TABLE IF NOT EXISTS school_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS schools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  school_year_id UUID REFERENCES school_years(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#4f6df5',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  scope TEXT NOT NULL DEFAULT 'group' CHECK (scope IN ('class','group','none')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ---------- Người dùng & vai trò ----------
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT,
  address TEXT,
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add role column if it doesn't exist
DO $$ BEGIN
  ALTER TABLE profiles ADD COLUMN role user_role NOT NULL DEFAULT 'student';
EXCEPTION
  WHEN duplicate_column THEN null;
END $$;

CREATE TABLE IF NOT EXISTS teachers (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  teacher_type TEXT NOT NULL DEFAULT 'subject' CHECK (teacher_type IN ('gvcn','subject','admin_staff')),
  homeroom_class_id UUID REFERENCES classes(id)
);

CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id),
  group_id UUID REFERENCES groups(id),
  student_code TEXT UNIQUE NOT NULL,
  date_of_birth DATE,
  gender TEXT,
  discipline_score NUMERIC(5,1) DEFAULT 100.0,
  attendance_rate NUMERIC(5,1) DEFAULT 100.0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS student_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  position_id UUID REFERENCES positions(id),
  group_id UUID REFERENCES groups(id),
  school_year_id UUID REFERENCES school_years(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ---------- Sơ đồ chỗ ngồi ----------
CREATE TABLE IF NOT EXISTS seating_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  student_id UUID REFERENCES students(id) ON DELETE CASCADE UNIQUE,
  seat_row INT NOT NULL,
  seat_col INT NOT NULL,
  school_year_id UUID REFERENCES school_years(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (group_id, seat_row, seat_col)
);

-- ---------- Thông báo ----------
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  is_important BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_announcements_class ON announcements(class_id);
CREATE INDEX IF NOT EXISTS idx_announcements_created ON announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_pinned ON announcements(is_pinned) WHERE is_pinned = true;

-- ---------- Lịch sử nề nếp ----------
CREATE TABLE IF NOT EXISTS discipline_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE NOT NULL,
  violation_type TEXT NOT NULL,
  points_deducted NUMERIC(5,1) NOT NULL DEFAULT 0,
  description TEXT,
  created_by UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_discipline_logs_student ON discipline_logs(student_id);
CREATE INDEX IF NOT EXISTS idx_discipline_logs_created ON discipline_logs(created_at DESC);

-- ============================================================
-- PART 2: RLS FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION current_role_is(target_role user_role)
RETURNS BOOLEAN LANGUAGE SQL STABLE AS $$
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = target_role AND is_active);
$$;

CREATE OR REPLACE FUNCTION is_gvcn_of(target_class_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM teachers t JOIN profiles p ON p.id = t.id
    WHERE t.id = auth.uid() AND t.teacher_type = 'gvcn' 
    AND t.homeroom_class_id = target_class_id AND p.is_active
  );
$$;

CREATE OR REPLACE FUNCTION can_post_announcement(p_user_id UUID, p_class_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_role TEXT;
  v_position_code TEXT;
BEGIN
  -- Check role first
  SELECT role INTO v_role FROM profiles WHERE id = p_user_id AND is_active = true;
  
  IF v_role = 'admin' OR v_role = 'teacher' THEN
    RETURN TRUE;
  END IF;
  
  -- Check if student has allowed position
  -- Note: This uses SECURITY DEFINER so it bypasses RLS on students table
  SELECT p.code INTO v_position_code
  FROM student_positions sp
  JOIN positions p ON p.id = sp.position_id
  JOIN students s ON s.id = sp.student_id
  WHERE sp.student_id = p_user_id 
  LIMIT 1;
  
  RETURN v_position_code IN ('lop_truong', 'bi_thu', 'lop_pho_hoc_tap', 'lop_pho');
END;
$$;

-- Update student position helper function
CREATE OR REPLACE FUNCTION update_student_position(p_student_id UUID, p_position_label TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_position_id UUID;
  v_group_id UUID;
  v_school_year_id UUID;
BEGIN
  -- Get position_id from label
  SELECT id INTO v_position_id FROM positions WHERE label = p_position_label;
  
  IF v_position_id IS NULL THEN
    RAISE EXCEPTION 'Position not found: %', p_position_label;
  END IF;
  
  -- Get student's group_id and current school_year
  SELECT s.group_id, sy.id INTO v_group_id, v_school_year_id
  FROM students s
  CROSS JOIN school_years sy
  WHERE s.id = p_student_id AND sy.is_current = true;
  
  -- Delete existing positions for this student
  DELETE FROM student_positions WHERE student_id = p_student_id;
  
  -- Insert new position
  INSERT INTO student_positions (student_id, position_id, group_id, school_year_id)
  VALUES (p_student_id, v_position_id, v_group_id, v_school_year_id);
END;
$$;

-- ============================================================
-- PART 3: ENABLE RLS
-- ============================================================

-- NOTE: Students table will use simplified RLS to avoid recursion

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- STUDENTS: RLS will be configured with simpler policies below
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE seating_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PART 4: RLS POLICIES
-- ============================================================

-- Profiles
DROP POLICY IF EXISTS self_read_profile ON profiles;
DROP POLICY IF EXISTS admin_full_profiles ON profiles;
DROP POLICY IF EXISTS profiles_select_self ON profiles;
DROP POLICY IF EXISTS profiles_select_all ON profiles;
DROP POLICY IF EXISTS profiles_update_self ON profiles;

-- Allow all authenticated users to read profiles (for displaying names)
CREATE POLICY profiles_select_all ON profiles FOR SELECT USING (auth.uid() IS NOT NULL);

-- Users can update their own profile
CREATE POLICY profiles_update_self ON profiles FOR UPDATE 
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Groups
DROP POLICY IF EXISTS read_groups ON groups;
DROP POLICY IF EXISTS admin_write_groups ON groups;
DROP POLICY IF EXISTS admin_update_groups ON groups;
CREATE POLICY read_groups ON groups FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_groups ON groups FOR INSERT WITH CHECK (current_role_is('admin'));
CREATE POLICY admin_update_groups ON groups FOR UPDATE USING (current_role_is('admin'));

-- Positions
DROP POLICY IF EXISTS read_positions ON positions;
DROP POLICY IF EXISTS admin_write_positions ON positions;
CREATE POLICY read_positions ON positions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_positions ON positions FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- School Years
DROP POLICY IF EXISTS read_school_years ON school_years;
DROP POLICY IF EXISTS admin_write_school_years ON school_years;
CREATE POLICY read_school_years ON school_years FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_write_school_years ON school_years FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- Students - SIMPLIFIED TO AVOID RECURSION
DROP POLICY IF EXISTS admin_full_students ON students;
DROP POLICY IF EXISTS gvcn_read_class_students ON students;
DROP POLICY IF EXISTS gvcn_update_class_students ON students;
DROP POLICY IF EXISTS student_read_own_class ON students;
DROP POLICY IF EXISTS student_read_self ON students;
DROP POLICY IF EXISTS student_update_self ON students;
DROP POLICY IF EXISTS students_select_policy ON students;

-- Admin can do everything
CREATE POLICY admin_full_students ON students FOR ALL
  USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));

-- GVCN can read and update their class
CREATE POLICY gvcn_full_class_students ON students FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM teachers t 
      WHERE t.id = auth.uid() 
      AND t.teacher_type = 'gvcn' 
      AND t.homeroom_class_id = students.class_id
    )
  );

-- Students can SELECT all rows (filtering done in application)
-- This avoids recursion by not checking class_id in the policy
CREATE POLICY students_select_policy ON students FOR SELECT
  USING (current_role_is('student'));

-- Students can only update their own record
CREATE POLICY student_update_self ON students FOR UPDATE 
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Student Positions
DROP POLICY IF EXISTS read_student_positions ON student_positions;
DROP POLICY IF EXISTS admin_gvcn_write_positions ON student_positions;
CREATE POLICY read_student_positions ON student_positions FOR SELECT USING (auth.uid() IS NOT NULL);
-- Fixed: Use SECURITY DEFINER function to avoid recursion
CREATE POLICY admin_gvcn_write_positions ON student_positions FOR ALL USING (
  current_role_is('admin') OR current_role_is('teacher')
);

-- Seating Positions
DROP POLICY IF EXISTS read_seating ON seating_positions;
DROP POLICY IF EXISTS admin_gvcn_write_seating ON seating_positions;
CREATE POLICY read_seating ON seating_positions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY admin_gvcn_write_seating ON seating_positions FOR ALL USING (
  current_role_is('admin') OR EXISTS (
    SELECT 1 FROM classes c WHERE c.id = seating_positions.class_id AND is_gvcn_of(c.id)
  )
);

-- Announcements
DROP POLICY IF EXISTS read_announcements ON announcements;
DROP POLICY IF EXISTS create_announcements ON announcements;
DROP POLICY IF EXISTS update_announcements ON announcements;
DROP POLICY IF EXISTS delete_announcements ON announcements;

-- Fixed: Students can read all announcements for authenticated users
-- Application will filter by class_id
CREATE POLICY read_announcements ON announcements FOR SELECT USING (
  auth.uid() IS NOT NULL
);

CREATE POLICY create_announcements ON announcements FOR INSERT WITH CHECK (
  created_by = auth.uid() AND (
    current_role_is('admin') OR 
    current_role_is('teacher') OR
    current_role_is('student')
  )
);

CREATE POLICY update_announcements ON announcements FOR UPDATE USING (
  created_by = auth.uid() OR current_role_is('admin') OR current_role_is('teacher')
);

CREATE POLICY delete_announcements ON announcements FOR DELETE USING (
  created_by = auth.uid() OR current_role_is('admin') OR current_role_is('teacher')
);

-- Discipline Logs
DROP POLICY IF EXISTS read_discipline_logs ON discipline_logs;
DROP POLICY IF EXISTS create_discipline_logs ON discipline_logs;

-- Fixed: Students can read their own logs, teachers/admin can read all
CREATE POLICY read_discipline_logs ON discipline_logs FOR SELECT USING (
  student_id = auth.uid() OR 
  current_role_is('admin') OR 
  current_role_is('teacher')
);

CREATE POLICY create_discipline_logs ON discipline_logs FOR INSERT WITH CHECK (
  current_role_is('admin') OR current_role_is('teacher')
);

-- ============================================================
-- PART 5: SEED DATA
-- ============================================================

-- Insert positions
INSERT INTO positions (code, label, scope) VALUES
  ('thanh_vien','Thành viên','group'),
  ('lop_truong','Lớp trưởng','class'),
  ('bi_thu','Bí thư','class'),
  ('lop_pho_hoc_tap','Lớp phó học tập','class'),
  ('lop_pho','Lớp phó','class'),
  ('to_truong','Tổ trưởng','group'),
  ('pho_to_truong','Phó tổ trưởng','group')
ON CONFLICT (code) DO NOTHING;

-- Insert school year
INSERT INTO school_years (name, start_date, end_date, is_current) VALUES
  ('2025-2026', '2025-09-05', '2026-05-31', TRUE)
ON CONFLICT DO NOTHING;

-- Insert school, class, and groups
DO $$
DECLARE
  v_school_id UUID;
  v_year_id UUID;
  v_class_id UUID;
BEGIN
  SELECT id INTO v_school_id FROM schools LIMIT 1;
  IF v_school_id IS NULL THEN
    INSERT INTO schools (name) VALUES ('Trường THPT') RETURNING id INTO v_school_id;
  END IF;

  SELECT id INTO v_year_id FROM school_years WHERE is_current = TRUE LIMIT 1;
  
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  IF v_class_id IS NULL THEN
    INSERT INTO classes (school_id, school_year_id, name)
    VALUES (v_school_id, v_year_id, '12A2') RETURNING id INTO v_class_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM groups WHERE class_id = v_class_id) THEN
    INSERT INTO groups (class_id, name, color) VALUES
      (v_class_id, 'Tổ 1', '#4f6df5'),
      (v_class_id, 'Tổ 2', '#22c9a8'),
      (v_class_id, 'Tổ 3', '#f5a524'),
      (v_class_id, 'Tổ 4', '#c05fd6');
  END IF;

  RAISE NOTICE '✓ Setup complete - Class ID: %', v_class_id;
END $$;

-- ============================================================
-- PART 6: CREATE STUDENT ACCOUNTS (40 students)
-- ============================================================

DO $$
DECLARE
  v_class_id UUID;
  v_group_ids UUID[];
  v_student RECORD;
  v_email TEXT;
  v_password TEXT := '12a2@2025';
  v_counter INT := 1;
  v_group_idx INT;
BEGIN
  -- Get class ID
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  
  IF v_class_id IS NULL THEN
    RAISE EXCEPTION 'Class 12A2 not found';
  END IF;
  
  -- Get all group IDs
  SELECT ARRAY_AGG(id ORDER BY name) INTO v_group_ids FROM groups WHERE class_id = v_class_id;
  
  RAISE NOTICE 'Creating 40 student accounts...';
  
  -- Create 40 students
  FOR v_counter IN 1..40 LOOP
    v_email := 'student' || LPAD(v_counter::TEXT, 2, '0') || '@12a2.edu.vn';
    v_group_idx := ((v_counter - 1) % 4) + 1;
    
    -- Check if auth user exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
      -- Insert into auth.users
      INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        v_email,
        crypt(v_password, gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{}'::jsonb
      );
      
      -- Get the created user ID
      DECLARE
        v_user_id UUID;
      BEGIN
        SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
        
        -- Insert profile
        INSERT INTO profiles (id, role, full_name, email) VALUES
          (v_user_id, 'student', 'Học sinh ' || LPAD(v_counter::TEXT, 2, '0'), v_email);
        
        -- Insert student
        INSERT INTO students (id, class_id, group_id, student_code, discipline_score) VALUES
          (v_user_id, v_class_id, v_group_ids[v_group_idx], LPAD(v_counter::TEXT, 2, '0'), 100.0);
        
        RAISE NOTICE '[%/40] Created: % - Tổ %', v_counter, v_email, v_group_idx;
      END;
    ELSE
      RAISE NOTICE '[%/40] Already exists: %', v_counter, v_email;
    END IF;
  END LOOP;
  
  RAISE NOTICE '✓ Student account creation complete';
END $$;

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================================';
  RAISE NOTICE '✓ TECH-STUDENT DATABASE SETUP COMPLETE';
  RAISE NOTICE '============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Login with admin account (create via Supabase Dashboard)';
  RAISE NOTICE '2. Student accounts: student01@12a2.edu.vn to student40@12a2.edu.vn';
  RAISE NOTICE '3. Default password: 12a2@2025';
  RAISE NOTICE '';
  RAISE NOTICE '============================================================';
END $$;


-- ============================================================
-- OPTIONAL: AVATAR STORAGE SETUP
-- ============================================================
-- Note: Storage buckets thường được tạo qua Supabase Dashboard
-- Hoặc chạy riêng file SETUP_AVATAR_STORAGE.sql
-- 
-- Nếu muốn tạo qua SQL, bỏ comment các dòng dưới:

/*
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'student-avatars',
  'student-avatars',
  true,
  2097152,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;
*/

-- ============================================================
-- END OF MASTER DATABASE SETUP
-- ============================================================
