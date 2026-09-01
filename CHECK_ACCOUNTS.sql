-- ============================================================
-- KIỂM TRA TÀI KHOẢN TRONG HỆ THỐNG
-- Chạy script này để xem tất cả tài khoản có thể đăng nhập
-- ============================================================

-- 1. Kiểm tra tất cả users trong auth.users
SELECT 
  au.id,
  au.email,
  au.role,
  au.email_confirmed_at,
  au.created_at,
  CASE 
    WHEN au.encrypted_password IS NOT NULL THEN '✓ Có password'
    ELSE '✗ Chưa có password'
  END as password_status
FROM auth.users au
ORDER BY au.email;

-- 2. Kiểm tra profiles tương ứng
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.role,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = p.id) THEN '✓ Có auth'
    ELSE '✗ Chưa có auth'
  END as auth_status
FROM profiles p
ORDER BY p.role, p.email;

-- 3. Kiểm tra học sinh đã có tài khoản chưa
SELECT 
  s.student_code,
  p.full_name,
  p.email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = s.id) THEN '✓ Có tài khoản'
    ELSE '✗ Chưa có tài khoản'
  END as account_status
FROM students s
JOIN profiles p ON p.id = s.id
WHERE s.class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
ORDER BY s.student_code;

-- 4. Test thử đăng nhập với password mặc định (chỉ kiểm tra cấu trúc)
SELECT 
  email,
  CASE 
    WHEN encrypted_password IS NOT NULL THEN 'Password đã set'
    ELSE 'Chưa có password'
  END as status
FROM auth.users
WHERE email LIKE '%@12a2.edu.vn'
ORDER BY email
LIMIT 5;
