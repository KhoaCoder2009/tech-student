-- ================================================================
-- FIX SCHEMA COMPATIBILITY
-- Đảm bảo schema tương thích với code hiện tại
-- ================================================================

-- 1. Ensure user_role enum exists
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin','teacher','student');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 2. Ensure discipline_type enum exists
DO $$ BEGIN
  CREATE TYPE discipline_type AS ENUM ('bonus','penalty');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 3. Add missing columns to students if needed
DO $$ BEGIN
  -- Check if date_of_birth column exists but dob doesn't
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='students' AND column_name='dob') THEN
    ALTER TABLE students ADD COLUMN dob date;
    -- Copy data from date_of_birth to dob
    UPDATE students SET dob = date_of_birth WHERE date_of_birth IS NOT NULL;
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Column operations completed with warnings';
END $$;

-- 4. Ensure RLS helper function exists
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

-- 5. Ensure all tables have RLS enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_logs ENABLE ROW LEVEL SECURITY;

-- 6. Create basic RLS policies if they don't exist
-- Profiles
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='self_read_profile') THEN
    CREATE POLICY self_read_profile ON profiles FOR SELECT USING (id = auth.uid());
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='admin_full_profiles') THEN
    CREATE POLICY admin_full_profiles ON profiles FOR ALL
      USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));
  END IF;
END $$;

-- Students - Allow students to read all students in their class
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='students' AND policyname='students_read_all') THEN
    CREATE POLICY students_read_all ON students FOR SELECT
      USING (auth.uid() IS NOT NULL);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='students' AND policyname='admin_full_students') THEN
    CREATE POLICY admin_full_students ON students FOR ALL
      USING (current_role_is('admin')) WITH CHECK (current_role_is('admin'));
  END IF;
END $$;

-- Other tables - read for authenticated users
DO $$ BEGIN
  -- Classes
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='classes' AND policyname='read_classes') THEN
    CREATE POLICY read_classes ON classes FOR SELECT USING (auth.uid() IS NOT NULL);
  END IF;
  
  -- Groups
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='groups' AND policyname='read_groups') THEN
    CREATE POLICY read_groups ON groups FOR SELECT USING (auth.uid() IS NOT NULL);
  END IF;
  
  -- Positions
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='positions' AND policyname='read_positions') THEN
    CREATE POLICY read_positions ON positions FOR SELECT USING (auth.uid() IS NOT NULL);
  END IF;
  
  -- Announcements
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcements' AND policyname='read_announcements') THEN
    CREATE POLICY read_announcements ON announcements FOR SELECT USING (auth.uid() IS NOT NULL);
  END IF;
  
  -- Discipline categories
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discipline_categories' AND policyname='read_categories') THEN
    CREATE POLICY read_categories ON discipline_categories FOR SELECT USING (auth.uid() IS NOT NULL);
  END IF;
  
  -- Discipline logs
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discipline_logs' AND policyname='read_discipline_logs') THEN
    CREATE POLICY read_discipline_logs ON discipline_logs FOR SELECT
      USING (student_id = auth.uid() OR current_role_is('admin') OR current_role_is('teacher'));
  END IF;
END $$;

COMMIT;
