-- =====================================================
-- XÓA CÁC CHỨC VỤ KHÔNG SỬ DỤNG
-- =====================================================
-- Script này xóa các chức vụ không cần thiết trong hệ thống
-- Chạy script này trong Supabase SQL Editor

-- Bước 1: Xem tất cả chức vụ hiện có
SELECT id, code, label, scope FROM positions ORDER BY label;

-- Bước 2: Xóa student_positions liên kết với các chức vụ không mong muốn
DELETE FROM student_positions 
WHERE position_id IN (
  SELECT id FROM positions 
  WHERE code IN (
    'ub_hoc_tap'
  ) OR label IN (
    'Lớp phó',
    'Thư ký', 
    'Ủy ban tuyên truyền',
    'Ủy ban văn thể',
    'Học tập',
    'Tuyên truyền'
  )
);

-- Bước 3: Xóa các chức vụ thừa
DELETE FROM positions 
WHERE code IN (
  'ub_hoc_tap'
) OR label IN (
  'Lớp phó',
  'Thư ký',
  'Ủy ban tuyên truyền',
  'Ủy ban văn thể',
  'Học tập',
  'Tuyên truyền'
);

-- Bước 3: Kiểm tra các chức vụ còn lại
SELECT id, code, label, scope 
FROM positions 
ORDER BY label;

-- Kết quả mong đợi: Chỉ còn các chức vụ chính từ schema.sql:
-- - thanh_vien (Thành viên)
-- - lop_truong (Lớp trưởng)
-- - lop_pho_hoc_tap (Lớp phó học tập)
-- - bi_thu (Bí thư)
-- - to_truong (Tổ trưởng)
-- - pho_to_truong (Phó tổ trưởng)
