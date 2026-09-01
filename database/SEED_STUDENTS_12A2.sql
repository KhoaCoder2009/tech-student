-- ================================================================
-- SEED 40 STUDENTS FOR CLASS 12A2
-- Chạy script này SAU KHI đã tạo xong admin account
-- ================================================================

DO $$
DECLARE
  v_counter integer;
  v_email text;
  v_user_id uuid;
  v_group_id uuid;
  v_group_idx integer;
  v_class_id uuid := '11111111-1111-1111-1111-111111111111'; -- 12A2
  v_gender text;
  v_groups uuid[] := ARRAY[
    '22222222-2222-2222-2222-222222222221'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '22222222-2222-2222-2222-222222222223'::uuid,
    '22222222-2222-2222-2222-222222222224'::uuid
  ];
BEGIN
  RAISE NOTICE 'Starting to create 40 students...';
  
  -- Create 40 students
  FOR v_counter IN 1..40 LOOP
    v_email := 'student' || LPAD(v_counter::TEXT, 2, '0') || '@12a2.edu.vn';
    v_group_idx := ((v_counter - 1) % 4) + 1;
    v_group_id := v_groups[v_group_idx];
    v_gender := CASE WHEN v_counter % 2 = 0 THEN 'Nữ' ELSE 'Nam' END;
    
    -- Check if user already exists in auth.users
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email LIMIT 1;
    
    IF v_user_id IS NULL THEN
      -- Create auth user (THIS REQUIRES service_role key, not anon key)
      -- In production, use Supabase Edge Function or Admin API
      RAISE NOTICE 'Skipping auth creation for %. Please create via Dashboard or Edge Function.', v_email;
      
      -- Generate a predictable UUID for demo
      v_user_id := uuid_generate_v5(
        '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
        v_email
      );
      
      -- Insert profile (will link when auth user is created)
      INSERT INTO profiles (id, role, full_name, email, is_active)
      VALUES (
        v_user_id,
        'student',
        'Học sinh ' || LPAD(v_counter::TEXT, 2, '0'),
        v_email,
        true
      )
      ON CONFLICT (id) DO NOTHING;
      
      -- Insert student record
      INSERT INTO students (
        id,
        student_code,
        gender,
        dob,
        class_id,
        group_id,
        discipline_score,
        attendance_rate
      )
      VALUES (
        v_user_id,
        '12A2' || LPAD(v_counter::TEXT, 2, '0'),
        v_gender,
        '2007-01-01'::date + (v_counter || ' days')::interval,
        v_class_id,
        v_group_id,
        100,
        100.00
      )
      ON CONFLICT (id) DO NOTHING;
      
    ELSE
      RAISE NOTICE 'User already exists: %', v_email;
    END IF;
    
  END LOOP;
  
  RAISE NOTICE 'Finished! Created profiles and student records.';
  RAISE NOTICE 'NOTE: Auth users must be created manually via Supabase Dashboard or Edge Function.';
  
END $$;

-- ================================================================
-- QUICK CREATE DEMO STUDENTS (Manual Method)
-- ================================================================
-- Nếu không muốn tạo 40 students, có thể tạo 3-5 students demo:
-- 
-- 1. Vào Supabase Dashboard → Authentication → Users
-- 2. Add User:
--    Email: student01@12a2.edu.vn
--    Password: student123
--    Auto Confirm: YES
-- 
-- 3. Copy User ID, chạy:
--
-- INSERT INTO profiles (id, role, full_name, email) VALUES
--   ('COPIED_USER_ID', 'student', 'Nguyễn Văn A', 'student01@12a2.edu.vn');
-- 
-- INSERT INTO students (id, student_code, gender, dob, class_id, group_id) VALUES
--   ('COPIED_USER_ID', '12A201', 'Nam', '2007-01-15', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221');
--
-- 4. Lặp lại cho student02, student03, etc.
-- ================================================================

COMMIT;
