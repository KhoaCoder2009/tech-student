-- ============================================================
-- RESET PASSWORD CHO ADMIN
-- Đặt lại password admin thành: admin@12a2
-- ============================================================

DO $$
DECLARE
  v_admin_email text := 'admin@techstudent.local';
  v_new_password text := 'Admin@123';
BEGIN
  -- Update password cho admin
  UPDATE auth.users
  SET 
    encrypted_password = crypt(v_new_password, gen_salt('bf')),
    updated_at = now(),
    email_confirmed_at = now()
  WHERE email = v_admin_email;
  
  IF FOUND THEN
    RAISE NOTICE '✓ Đã reset password cho admin';
    RAISE NOTICE 'Email: %', v_admin_email;
    RAISE NOTICE 'Password mới: %', v_new_password;
  ELSE
    RAISE NOTICE '✗ Không tìm thấy admin với email: %', v_admin_email;
    RAISE NOTICE 'Đang tạo tài khoản admin mới...';
    
    -- Nếu không tìm thấy, tạo mới
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
      raw_user_meta_data,
      is_super_admin,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      v_admin_email,
      crypt(v_new_password, gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      false,
      '',
      '',
      '',
      ''
    );
    
    RAISE NOTICE '✓ Đã tạo tài khoản admin mới';
  END IF;
END $$;

-- Xem lại thông tin admin
SELECT 
  email,
  role,
  email_confirmed_at,
  'Password: Admin@123' as note
FROM auth.users
WHERE email = 'admin@techstudent.local';
