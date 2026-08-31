-- ============================================================
-- UPDATE ANNOUNCEMENT PERMISSIONS
-- Sửa function để admin luôn có quyền đăng thông báo
-- ============================================================

-- Drop policy trước, sau đó drop function, rồi tạo lại
DROP POLICY IF EXISTS create_announcements ON announcements;

DROP FUNCTION IF EXISTS can_post_announcement(uuid, uuid);

CREATE OR REPLACE FUNCTION can_post_announcement(p_user_id uuid, p_class_id uuid)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_role text;
  v_position_code text;
BEGIN
  -- Kiểm tra role trước - ADMIN/TEACHER luôn có quyền
  SELECT role INTO v_role FROM profiles WHERE id = p_user_id;
  
  IF v_role = 'admin' OR v_role = 'teacher' THEN
    RETURN true;  -- Admin/Teacher luôn có quyền đăng, không cần kiểm tra thêm
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

-- Tạo lại policy
CREATE POLICY create_announcements ON announcements FOR INSERT WITH CHECK (
  created_by = auth.uid() AND can_post_announcement(auth.uid(), class_id)
);

-- Test
DO $$
DECLARE
  v_admin_id uuid;
  v_class_id uuid;
  v_can_post boolean;
BEGIN
  -- Lấy admin và class
  SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
  SELECT id INTO v_class_id FROM classes WHERE name = '12A2' LIMIT 1;
  
  -- Test quyền
  SELECT can_post_announcement(v_admin_id, v_class_id) INTO v_can_post;
  
  IF v_can_post THEN
    RAISE NOTICE '✓ Admin có quyền đăng thông báo';
  ELSE
    RAISE NOTICE '✗ Admin KHÔNG có quyền đăng thông báo (LỖI!)';
  END IF;
END $$;

COMMENT ON FUNCTION can_post_announcement IS 'Kiểm tra quyền đăng thông báo - Admin/Teacher luôn được phép';
