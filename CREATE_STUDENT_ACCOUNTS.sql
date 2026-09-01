-- ============================================================
-- CREATE STUDENT ACCOUNTS WITH DEFAULT PASSWORD
-- Tạo tài khoản cho 40 học sinh với password mặc định: 12a2@2025
-- ============================================================

DO $$
DECLARE
  v_class_id uuid;
  v_student record;
  v_email text;
  v_password text := '12a2@2025'; -- Password mặc định
BEGIN
  -- Lấy class 12A2
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  
  IF v_class_id IS NULL THEN
    RAISE EXCEPTION 'Không tìm thấy lớp 12A2';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'TẠO TÀI KHOẢN HỌC SINH LỚP 12A2';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Password mặc định: %', v_password;
  RAISE NOTICE '';

  -- Duyệt qua từng học sinh
  FOR v_student IN 
    SELECT 
      s.id,
      s.student_code,
      p.full_name
    FROM students s
    JOIN profiles p ON p.id = s.id
    WHERE s.class_id = v_class_id
    ORDER BY s.student_code
  LOOP
    -- Tạo email từ student_code
    v_email := 'student' || v_student.student_code || '@12a2.edu.vn';
    
    -- Kiểm tra xem user đã tồn tại trong auth.users chưa
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
      -- Nếu đã có, chỉ update password
      UPDATE auth.users
      SET encrypted_password = crypt(v_password, gen_salt('bf'))
      WHERE email = v_email;
      
      RAISE NOTICE '[UPDATE] % - % - %', v_student.student_code, v_student.full_name, v_email;
    ELSE
      -- Nếu chưa có, tạo mới
      INSERT INTO auth.users (
        id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        instance_id,
        aud,
        role
      ) VALUES (
        v_student.id,
        v_email,
        crypt(v_password, gen_salt('bf')),
        now(),
        now(),
        now(),
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated'
      );
      
      -- Update profile email
      UPDATE profiles
      SET email = v_email
      WHERE id = v_student.id;
      
      RAISE NOTICE '[CREATE] % - % - %', v_student.student_code, v_student.full_name, v_email;
    END IF;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✓ HOÀN TẤT TẠO TÀI KHOẢN';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Tất cả học sinh có thể đăng nhập với:';
  RAISE NOTICE '  Email: student01@12a2.edu.vn đến student40@12a2.edu.vn';
  RAISE NOTICE '  Password: %', v_password;
  RAISE NOTICE '';
END $$;

-- Xuất danh sách tài khoản
SELECT 
  s.student_code as "Mã HS",
  p.full_name as "Họ tên",
  p.email as "Email",
  '12a2@2025' as "Password",
  g.name as "Tổ"
FROM students s
JOIN profiles p ON p.id = s.id
LEFT JOIN groups g ON g.id = s.group_id
WHERE s.class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
ORDER BY s.student_code;
