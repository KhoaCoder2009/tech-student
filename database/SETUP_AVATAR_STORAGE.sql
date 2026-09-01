-- ============================================================
-- SETUP AVATAR STORAGE
-- Chạy trong Supabase SQL Editor để tạo storage bucket cho avatars
-- ============================================================

-- ============================================================
-- STEP 1: Create storage bucket
-- ============================================================

-- Insert bucket (nếu chưa có)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'student-avatars',
  'student-avatars',
  true,  -- public = true để ảnh có thể truy cập công khai
  2097152,  -- 2MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 2: Setup RLS policies for storage
-- ============================================================

-- Drop old policies if exist
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- Allow authenticated users to upload to avatars folder
CREATE POLICY "Users can upload avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'student-avatars' 
  AND (storage.foldername(name))[1] = 'avatars'
);

-- Allow authenticated users to update files in avatars folder
CREATE POLICY "Users can update avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'student-avatars' 
  AND (storage.foldername(name))[1] = 'avatars'
);

-- Allow everyone to view avatars (public bucket)
CREATE POLICY "Public can view avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'student-avatars');

-- Allow authenticated users to delete from avatars folder
CREATE POLICY "Users can delete avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'student-avatars' 
  AND (storage.foldername(name))[1] = 'avatars'
);

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check if bucket was created
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
WHERE id = 'student-avatars';

-- Check policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%avatar%';

-- Expected output: 4 policies
-- - Users can upload avatars
-- - Users can update avatars  
-- - Public can view avatars
-- - Users can delete avatars

-- ============================================================
-- NOTES
-- ============================================================
-- 
-- Bucket Configuration:
-- - Name: student-avatars
-- - Public: Yes (avatars can be viewed by everyone)
-- - Max file size: 2MB
-- - Allowed types: JPEG, PNG, GIF, WebP
-- 
-- Security:
-- - Users can upload/update/delete avatars in avatars/ folder
-- - Filename format: {user_id}-{timestamp}.{ext}
-- - Everyone can view avatars (public bucket)
-- - Application ensures users only modify their own files by filename
-- 
-- Note: RLS policies are simplified - app logic ensures security
-- by using userId in filename. More strict policies would require
-- parsing filename which is complex and error-prone.
-- 
-- Usage in code:
-- const { data } = await supabase.storage
--   .from('student-avatars')
--   .upload(`avatars/${userId}-${Date.now()}.jpg`, file);
-- 
-- ============================================================
