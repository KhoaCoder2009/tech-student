-- ============================================================
-- ADD PROFILE FIELDS
-- Thêm các trường thông tin cá nhân vào bảng profiles
-- ============================================================

-- Thêm các cột mới vào profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS date_of_birth date,
ADD COLUMN IF NOT EXISTS gender text CHECK (gender IN ('Nam', 'Nữ', NULL)),
ADD COLUMN IF NOT EXISTS address text;

-- Thêm index cho phone để tìm kiếm nhanh
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);

-- Comment
COMMENT ON COLUMN profiles.phone IS 'Số điện thoại liên lạc';
COMMENT ON COLUMN profiles.date_of_birth IS 'Ngày sinh';
COMMENT ON COLUMN profiles.gender IS 'Giới tính (Nam/Nữ)';
COMMENT ON COLUMN profiles.address IS 'Địa chỉ liên lạc';

-- Test
DO $$
BEGIN
  RAISE NOTICE '✓ Đã thêm các cột: phone, date_of_birth, gender, address vào bảng profiles';
END $$;

-- Kiểm tra cấu trúc bảng
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('phone', 'date_of_birth', 'gender', 'address')
ORDER BY column_name;
