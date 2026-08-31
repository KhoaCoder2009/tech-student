-- ============================================================
-- TECH-STUDENT SETUP SCRIPT
-- Chạy script này MỘT LẦN sau khi import schema
-- ============================================================

-- 1. Xóa duplicate classes (chỉ giữ 1 class 12A2)
DO $$
DECLARE
  v_keep_class_id uuid;
BEGIN
  -- Giữ class mới nhất
  SELECT id INTO v_keep_class_id 
  FROM classes 
  WHERE name = '12A2' 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  -- Update students sang class mới nhất
  UPDATE students 
  SET class_id = v_keep_class_id 
  WHERE class_id IN (SELECT id FROM classes WHERE name = '12A2' AND id != v_keep_class_id);
  
  -- Xóa classes cũ
  DELETE FROM classes WHERE name = '12A2' AND id != v_keep_class_id;
  
  RAISE NOTICE '✓ Cleaned duplicate classes';
END $$;

-- 2. Xóa duplicate groups
UPDATE students SET group_id = NULL;
DELETE FROM student_positions;
DELETE FROM groups;

-- 3. Tạo lại 4 tổ
DO $$
DECLARE
  v_class_id uuid;
BEGIN
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  
  INSERT INTO groups (class_id, name, color) VALUES
    (v_class_id, 'Tổ 1', '#4f6df5'),
    (v_class_id, 'Tổ 2', '#14b8a6'),
    (v_class_id, 'Tổ 3', '#f59e0b'),
    (v_class_id, 'Tổ 4', '#ef4444');
  
  RAISE NOTICE '✓ Created 4 groups';
END $$;

-- 4. Phân học sinh vào tổ và tạo seating positions
DO $$
DECLARE
  v_g1 uuid; v_g2 uuid; v_g3 uuid; v_g4 uuid;
  v_class_id uuid;
BEGIN
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  SELECT id INTO v_g1 FROM groups WHERE name = 'Tổ 1' LIMIT 1;
  SELECT id INTO v_g2 FROM groups WHERE name = 'Tổ 2' LIMIT 1;
  SELECT id INTO v_g3 FROM groups WHERE name = 'Tổ 3' LIMIT 1;
  SELECT id INTO v_g4 FROM groups WHERE name = 'Tổ 4' LIMIT 1;
  
  -- Xóa seating positions cũ
  DELETE FROM seating_positions;
  
  -- TỔ 1 (cột trái nhất)
  -- Hàng 5 (xa bảng nhất): Tuyết Nhi (23), Thanh Tuyền (35)
  UPDATE students SET group_id = v_g1 WHERE student_code = '23';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 5, 1 FROM students WHERE student_code = '23';
  
  UPDATE students SET group_id = v_g1 WHERE student_code = '35';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 5, 2 FROM students WHERE student_code = '35';
  
  -- Hàng 4: Bảo Châu (04), Minh Tướng (36)
  UPDATE students SET group_id = v_g1 WHERE student_code = '04';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 4, 1 FROM students WHERE student_code = '04';
  
  UPDATE students SET group_id = v_g1 WHERE student_code = '36';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 4, 2 FROM students WHERE student_code = '36';
  
  -- Hàng 3: Minh Châu (05), Như Ngọc (20)
  UPDATE students SET group_id = v_g1 WHERE student_code = '05';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 3, 1 FROM students WHERE student_code = '05';
  
  UPDATE students SET group_id = v_g1 WHERE student_code = '20';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 3, 2 FROM students WHERE student_code = '20';
  
  -- Hàng 2: Trung Nghĩa (19), Tiến Đạt (08)
  UPDATE students SET group_id = v_g1 WHERE student_code = '19';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 2, 1 FROM students WHERE student_code = '19';
  
  UPDATE students SET group_id = v_g1 WHERE student_code = '08';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 2, 2 FROM students WHERE student_code = '08';
  
  -- Hàng 1 (gần bảng nhất): Hoàng Thái (30), Hữu Ngọc (21)
  UPDATE students SET group_id = v_g1 WHERE student_code = '30';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 1, 1 FROM students WHERE student_code = '30';
  
  UPDATE students SET group_id = v_g1 WHERE student_code = '21';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g1, id, 1, 2 FROM students WHERE student_code = '21';
  
  -- TỔ 2 (cột 2 từ trái)
  -- Hàng 5: Phương Vy (39), Thu Nguyệt (22)
  UPDATE students SET group_id = v_g2 WHERE student_code = '39';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 5, 3 FROM students WHERE student_code = '39';
  
  UPDATE students SET group_id = v_g2 WHERE student_code = '22';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 5, 4 FROM students WHERE student_code = '22';
  
  -- Hàng 4: Minh Tâm (29), Tấn Lực (17)
  UPDATE students SET group_id = v_g2 WHERE student_code = '29';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 4, 3 FROM students WHERE student_code = '29';
  
  UPDATE students SET group_id = v_g2 WHERE student_code = '17';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 4, 4 FROM students WHERE student_code = '17';
  
  -- Hàng 3: Tâm Như (24), Minh Thiên (31)
  UPDATE students SET group_id = v_g2 WHERE student_code = '24';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 3, 3 FROM students WHERE student_code = '24';
  
  UPDATE students SET group_id = v_g2 WHERE student_code = '31';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 3, 4 FROM students WHERE student_code = '31';
  
  -- Hàng 2: Mai Phương (27), Trúc Vy (40)
  UPDATE students SET group_id = v_g2 WHERE student_code = '27';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 2, 3 FROM students WHERE student_code = '27';
  
  UPDATE students SET group_id = v_g2 WHERE student_code = '40';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 2, 4 FROM students WHERE student_code = '40';
  
  -- Hàng 1: Xuân Huy (13), Thị Vi (37)
  UPDATE students SET group_id = v_g2 WHERE student_code = '13';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 1, 3 FROM students WHERE student_code = '13';
  
  UPDATE students SET group_id = v_g2 WHERE student_code = '37';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g2, id, 1, 4 FROM students WHERE student_code = '37';
  
  -- TỔ 3 (cột 3 từ trái)
  -- Hàng 5: Xuân Linh (16), Yến Vy (38)
  UPDATE students SET group_id = v_g3 WHERE student_code = '16';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 5, 5 FROM students WHERE student_code = '16';
  
  UPDATE students SET group_id = v_g3 WHERE student_code = '38';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 5, 6 FROM students WHERE student_code = '38';
  
  -- Hàng 4: Minh Ánh (03), Anh Đào (07)
  UPDATE students SET group_id = v_g3 WHERE student_code = '03';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 4, 5 FROM students WHERE student_code = '03';
  
  UPDATE students SET group_id = v_g3 WHERE student_code = '07';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 4, 6 FROM students WHERE student_code = '07';
  
  -- Hàng 3: Ngọc Trâm (34), Gia Hân (11)
  UPDATE students SET group_id = v_g3 WHERE student_code = '34';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 3, 5 FROM students WHERE student_code = '34';
  
  UPDATE students SET group_id = v_g3 WHERE student_code = '11';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 3, 6 FROM students WHERE student_code = '11';
  
  -- Hàng 2: Hoàng Hải (10), Quốc An (01)
  UPDATE students SET group_id = v_g3 WHERE student_code = '10';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 2, 5 FROM students WHERE student_code = '10';
  
  UPDATE students SET group_id = v_g3 WHERE student_code = '01';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 2, 6 FROM students WHERE student_code = '01';
  
  -- Hàng 1: Quốc Huy (12), Thiên Phúc (26)
  UPDATE students SET group_id = v_g3 WHERE student_code = '12';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 1, 5 FROM students WHERE student_code = '12';
  
  UPDATE students SET group_id = v_g3 WHERE student_code = '26';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g3, id, 1, 6 FROM students WHERE student_code = '26';
  
  -- TỔ 4 (cột phải nhất)
  -- Hàng 5: Ngọc Thùy (32), Kim Thủy (33)
  UPDATE students SET group_id = v_g4 WHERE student_code = '32';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 5, 7 FROM students WHERE student_code = '32';
  
  UPDATE students SET group_id = v_g4 WHERE student_code = '33';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 5, 8 FROM students WHERE student_code = '33';
  
  -- Hàng 4: Hoàng Sơn (28), Trần Khoa (15)
  UPDATE students SET group_id = v_g4 WHERE student_code = '28';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 4, 7 FROM students WHERE student_code = '28';
  
  UPDATE students SET group_id = v_g4 WHERE student_code = '15';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 4, 8 FROM students WHERE student_code = '15';
  
  -- Hàng 3: Lê Khoa (14), Chấn Phong (25)
  UPDATE students SET group_id = v_g4 WHERE student_code = '14';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 3, 7 FROM students WHERE student_code = '14';
  
  UPDATE students SET group_id = v_g4 WHERE student_code = '25';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 3, 8 FROM students WHERE student_code = '25';
  
  -- Hàng 2: Bảo Anh (02), Thanh Giang (09)
  UPDATE students SET group_id = v_g4 WHERE student_code = '02';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 2, 7 FROM students WHERE student_code = '02';
  
  UPDATE students SET group_id = v_g4 WHERE student_code = '09';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 2, 8 FROM students WHERE student_code = '09';
  
  -- Hàng 1: Ngọc My (18), Mỹ Duyên (06)
  UPDATE students SET group_id = v_g4 WHERE student_code = '18';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 1, 7 FROM students WHERE student_code = '18';
  
  UPDATE students SET group_id = v_g4 WHERE student_code = '06';
  INSERT INTO seating_positions (class_id, group_id, student_id, seat_row, seat_col)
  SELECT v_class_id, v_g4, id, 1, 8 FROM students WHERE student_code = '06';
  
  RAISE NOTICE '✓ Assigned students to groups with seating positions';
END $$;

-- 5. Gán chức vụ (không cần năm học)
DO $$
DECLARE
  v_position_id uuid;
BEGIN
  SELECT id INTO v_position_id FROM positions WHERE code = 'thanh_vien' LIMIT 1;
  
  INSERT INTO student_positions (student_id, position_id, group_id)
  SELECT s.id, v_position_id, s.group_id
  FROM students s
  WHERE s.group_id IS NOT NULL;
  
  RAISE NOTICE '✓ Assigned positions';
END $$;

-- 6. Kết quả
SELECT 
  g.name as "Tổ",
  COUNT(s.id) as "Số HS"
FROM groups g
LEFT JOIN students s ON s.group_id = g.id
GROUP BY g.id, g.name
ORDER BY g.name;

-- 7. Setup discipline categories
DO $$
BEGIN
  -- Tạo type nếu chưa có
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'discipline_type') THEN
    CREATE TYPE discipline_type AS ENUM ('add', 'subtract');
  END IF;
  
  -- Tạo bảng nếu chưa có
  CREATE TABLE IF NOT EXISTS discipline_categories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type discipline_type NOT NULL,
    code text UNIQUE NOT NULL,
    label text NOT NULL,
    default_points numeric(4,1) NOT NULL DEFAULT 2.0,
    description text,
    created_at timestamptz DEFAULT now()
  );
  
  -- Seed categories
  INSERT INTO discipline_categories (type, code, label, default_points, description) VALUES
    ('add', 'duty_well', 'Trực nhật tốt', 2.0, 'Hoàn thành tốt nhiệm vụ trực nhật'),
    ('add', 'activity', 'Tham gia hoạt động', 3.0, 'Tích cực tham gia hoạt động tập thể'),
    ('add', 'help_class', 'Giúp đỡ tập thể', 2.0, 'Giúp đỡ bạn bè, tập thể lớp'),
    ('add', 'achievement', 'Thành tích', 5.0, 'Đạt thành tích học tập, thể thao, văn nghệ'),
    ('subtract', 'late', 'Đi học muộn', 1.0, 'Đến lớp sau giờ quy định'),
    ('subtract', 'no_uniform', 'Không đồng phục', 2.0, 'Không mặc đồng phục theo quy định'),
    ('subtract', 'no_duty', 'Không trực nhật', 3.0, 'Không thực hiện nhiệm vụ trực nhật'),
    ('subtract', 'violation', 'Vi phạm nội quy', 5.0, 'Vi phạm nội quy lớp, trường')
  ON CONFLICT (code) DO NOTHING;
  
  RAISE NOTICE '✓ Setup discipline categories';
END $$;

SELECT '✓ SETUP COMPLETE - Reload web now!' as status;
