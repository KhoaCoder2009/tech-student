-- ============================================================
-- ANNOUNCEMENTS SYSTEM - SIMPLIFIED
-- Thông báo theo chức vụ: GVCN, Bí thư, Lớp trưởng, Phó học tập, Phó lao động
-- ============================================================

-- Xóa bảng cũ nếu có (nếu đã chạy migration 005)
DROP TABLE IF EXISTS announcement_comments CASCADE;
DROP TABLE IF EXISTS announcement_views CASCADE;
DROP TABLE IF EXISTS announcement_permissions CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS announcement_tags CASCADE;
DROP TYPE IF EXISTS announcement_priority CASCADE;

-- Tạo bảng thông báo đơn giản
CREATE TABLE announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id uuid REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
  
  -- Nội dung
  title text NOT NULL,
  content text NOT NULL,
  
  -- Người đăng (BẤT KỲ AI cũng có thể đăng)
  created_by uuid REFERENCES profiles(id) NOT NULL,
  
  -- Thời gian
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Trạng thái
  is_pinned boolean NOT NULL DEFAULT false,
  is_important boolean NOT NULL DEFAULT false -- Đánh dấu quan trọng
);

CREATE INDEX idx_announcements_class ON announcements(class_id);
CREATE INDEX idx_announcements_created ON announcements(created_at DESC);
CREATE INDEX idx_announcements_pinned ON announcements(is_pinned) WHERE is_pinned = true;

-- View để hiển thị thông báo kèm thông tin người đăng VÀ CHỨC VỤ (nếu có)
CREATE OR REPLACE VIEW announcements_with_author AS
SELECT 
  a.*,
  p.full_name as author_name,
  p.role as author_role,
  -- Lấy chức vụ của người đăng (nếu là học sinh)
  COALESCE(pos.label, 
    CASE 
      WHEN p.role = 'admin' THEN 'Admin'
      WHEN p.role = 'teacher' THEN 'GVCN'
      ELSE NULL
    END
  ) as position_label,
  -- Màu tag theo chức vụ
  CASE 
    WHEN p.role = 'admin' THEN '#8b5cf6'
    WHEN p.role = 'teacher' THEN '#4f6df5'
    WHEN pos.code = 'lop_truong' THEN '#ef4444'
    WHEN pos.code = 'bi_thu' THEN '#f59e0b'
    WHEN pos.code = 'pho_hoc_tap' THEN '#14b8a6'
    WHEN pos.code = 'pho_lao_dong' THEN '#8b5cf6'
    ELSE '#64748b'
  END as position_color,
  -- Icon theo chức vụ
  CASE 
    WHEN p.role = 'admin' THEN '👨‍💼'
    WHEN p.role = 'teacher' THEN '👨‍🏫'
    WHEN pos.code = 'lop_truong' THEN '👑'
    WHEN pos.code = 'bi_thu' THEN '📋'
    WHEN pos.code = 'pho_hoc_tap' THEN '📚'
    WHEN pos.code = 'pho_lao_dong' THEN '🧹'
    ELSE '👤'
  END as position_icon
FROM announcements a
JOIN profiles p ON p.id = a.created_by
LEFT JOIN student_positions sp ON sp.student_id = a.created_by
LEFT JOIN positions pos ON pos.id = sp.position_id;

-- RLS Policies
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Function kiểm tra user có chức vụ được phép đăng không
CREATE OR REPLACE FUNCTION can_post_announcement(p_user_id uuid, p_class_id uuid)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_role text;
  v_position_code text;
BEGIN
  -- Kiểm tra nếu là admin/GVCN - ƯU TIÊN KIỂM TRA TRƯỚC
  SELECT role INTO v_role FROM profiles WHERE id = p_user_id;
  
  IF v_role = 'admin' OR v_role = 'teacher' THEN
    RETURN true;  -- Admin/Teacher luôn có quyền đăng
  END IF;
  
  -- Nếu không phải admin/teacher, kiểm tra chức vụ học sinh
  SELECT p.code INTO v_position_code
  FROM student_positions sp
  JOIN positions p ON p.id = sp.position_id
  JOIN students s ON s.id = sp.student_id
  WHERE sp.student_id = p_user_id 
    AND s.class_id = p_class_id
  LIMIT 1;
  
  -- Chỉ cho phép 4 chức vụ này đăng thông báo
  RETURN v_position_code IN ('lop_truong', 'bi_thu', 'pho_hoc_tap', 'pho_lao_dong');
END;
$$;

-- Đọc: Tất cả học sinh trong lớp + Admin/GVCN
CREATE POLICY read_announcements ON announcements FOR SELECT USING (
  EXISTS(
    SELECT 1 FROM students s 
    WHERE s.id = auth.uid() AND s.class_id = announcements.class_id
  ) OR
  auth.uid() IN (
    SELECT id FROM profiles WHERE role IN ('admin', 'teacher')
  )
);

-- Tạo: CHỈ người có chức vụ (GVCN, Lớp trưởng, Bí thư, Phó học tập, Phó lao động)
CREATE POLICY create_announcements ON announcements FOR INSERT WITH CHECK (
  created_by = auth.uid() AND can_post_announcement(auth.uid(), class_id)
);

-- Sửa: Chỉ người tạo hoặc GVCN
CREATE POLICY update_announcements ON announcements FOR UPDATE USING (
  created_by = auth.uid() OR
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('admin', 'teacher'))
);

-- Xóa: Chỉ người tạo hoặc GVCN
CREATE POLICY delete_announcements ON announcements FOR DELETE USING (
  created_by = auth.uid() OR
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('admin', 'teacher'))
);

-- Seed một thông báo mẫu từ GVCN
DO $$
DECLARE
  v_admin_id uuid;
  v_class_id uuid;
BEGIN
  SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  
  IF v_admin_id IS NOT NULL AND v_class_id IS NOT NULL THEN
    INSERT INTO announcements (
      class_id, 
      title, 
      content, 
      created_by,
      is_pinned,
      is_important
    ) VALUES (
      v_class_id,
      'Chào mừng đến với hệ thống thông báo lớp 12A2',
      'Đây là hệ thống thông báo của lớp. Chỉ GVCN, Lớp trưởng, Bí thư, Phó học tập, Phó lao động mới có quyền đăng thông báo. Mỗi tin nhắn sẽ hiển thị tag chức vụ và tên người đăng.',
      v_admin_id,
      true,
      true
    );
    
    RAISE NOTICE '✓ Đã tạo thông báo mẫu';
  END IF;
END $$;

COMMENT ON TABLE announcements IS 'Thông báo lớp học - chỉ người có chức vụ mới được đăng';
COMMENT ON FUNCTION can_post_announcement IS 'Kiểm tra user có quyền đăng thông báo (GVCN, LT, BT, PHT, PLD)';
