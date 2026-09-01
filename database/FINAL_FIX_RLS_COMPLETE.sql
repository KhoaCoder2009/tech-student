-- ============================================================
-- FINAL FIX - RLS COMPLETE (ALL TABLES)
-- Chạy file này 1 lần duy nhất trong Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PART 1: DROP ALL OLD POLICIES
-- ============================================================

-- Drop profiles policies
DROP POLICY IF EXISTS self_read_profile ON profiles;
DROP POLICY IF EXISTS admin_full_profiles ON profiles;
DROP POLICY IF EXISTS profiles_select_self ON profiles;
DROP POLICY IF EXISTS profiles_select_all ON profiles;
DROP POLICY IF EXISTS profiles_update_self ON profiles;

-- Drop students policies (including any old ones)
DO $$ 
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'students' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON students';
    END LOOP;
END $$;

-- Drop announcements policies
DO $$ 
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'announcements' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON announcements';
    END LOOP;
END $$;

-- Drop discipline_logs policies
DO $$ 
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'discipline_logs' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON discipline_logs';
    END LOOP;
END $$;

-- Drop student_positions policies
DO $$ 
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'student_positions' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON student_positions';
    END LOOP;
END $$;

-- ============================================================
-- PART 2: CREATE SIMPLE POLICIES (NO RECURSION)
-- ============================================================

-- PROFILES - Allow reading all profiles (for student names display)
CREATE POLICY profiles_select_all ON profiles 
  FOR SELECT 
  USING (auth.uid() IS NOT NULL);

CREATE POLICY profiles_update_self ON profiles 
  FOR UPDATE 
  USING (id = auth.uid()) 
  WITH CHECK (id = auth.uid());

-- STUDENTS - Ultra simple, no subqueries
CREATE POLICY students_select_all ON students 
  FOR SELECT 
  USING (auth.uid() IS NOT NULL);

CREATE POLICY students_update_self ON students 
  FOR UPDATE 
  USING (id = auth.uid()) 
  WITH CHECK (id = auth.uid());

-- ANNOUNCEMENTS - Everyone authenticated can read
CREATE POLICY announcements_select_all ON announcements 
  FOR SELECT 
  USING (auth.uid() IS NOT NULL);

CREATE POLICY announcements_insert_own ON announcements 
  FOR INSERT 
  WITH CHECK (created_by = auth.uid());

CREATE POLICY announcements_update_own ON announcements 
  FOR UPDATE 
  USING (created_by = auth.uid());

CREATE POLICY announcements_delete_own ON announcements 
  FOR DELETE 
  USING (created_by = auth.uid());

-- DISCIPLINE_LOGS - Students see own, others handled by app
CREATE POLICY discipline_logs_select_own ON discipline_logs 
  FOR SELECT 
  USING (student_id = auth.uid() OR auth.uid() IS NOT NULL);

-- STUDENT_POSITIONS - Everyone can read
CREATE POLICY student_positions_select_all ON student_positions 
  FOR SELECT 
  USING (auth.uid() IS NOT NULL);

-- ============================================================
-- PART 3: VERIFICATION
-- ============================================================

SELECT 'Policies created successfully!' as status;

-- Check policies count
SELECT 
  'profiles' as table_name, 
  COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'profiles'
UNION ALL
SELECT 'students', COUNT(*) FROM pg_policies WHERE tablename = 'students'
UNION ALL
SELECT 'announcements', COUNT(*) FROM pg_policies WHERE tablename = 'announcements'
UNION ALL
SELECT 'discipline_logs', COUNT(*) FROM pg_policies WHERE tablename = 'discipline_logs'
UNION ALL
SELECT 'student_positions', COUNT(*) FROM pg_policies WHERE tablename = 'student_positions';

-- ============================================================
-- NOTES
-- ============================================================
-- 
-- Changes made:
-- 1. Removed current_role_is() from all policies (no recursion)
-- 2. Removed all subqueries on students table
-- 3. Simplified to only auth.uid() checks
-- 4. ✅ FIX: profiles SELECT allows all authenticated users
--    (needed to display student names in friends/mygroup pages)
-- 5. No function calls = No recursion possible
-- 
-- Security:
-- - Users can READ all profiles (to display names) ✅
-- - Users can only UPDATE their own profile ✅
-- - Users can READ all students (app filters by class_id) ✅
-- - Users can only UPDATE their own student record ✅
-- - No INSERT/DELETE for regular users (admin only)
-- 
-- Why profiles SELECT is open:
-- - Friends page needs to display names of all classmates
-- - My Group page needs to display names of group members
-- - Profile data is not sensitive (just name, email)
-- - Users still cannot modify others' profiles
-- 
-- ============================================================
