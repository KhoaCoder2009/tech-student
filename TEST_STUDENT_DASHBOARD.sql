-- ============================================================
-- TEST STUDENT DASHBOARD DATA
-- Kiểm tra tất cả data cần thiết cho Student Dashboard
-- ============================================================

-- 1. Kiểm tra học sinh có trong database không
SELECT 
  s.id,
  s.student_code,
  s.discipline_score,
  s.group_id,
  p.full_name,
  p.email
FROM students s
JOIN profiles p ON p.id = s.id
WHERE s.class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
ORDER BY s.student_code
LIMIT 5;

-- 2. Kiểm tra groups có data không
SELECT 
  g.id,
  g.name,
  g.color,
  COUNT(s.id) as student_count
FROM groups g
LEFT JOIN students s ON s.group_id = g.id
WHERE g.class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
GROUP BY g.id, g.name, g.color
ORDER BY g.name;

-- 3. Kiểm tra positions
SELECT 
  p.id,
  p.code,
  p.label,
  p.scope
FROM positions
ORDER BY p.code;

-- 4. Kiểm tra student_positions (chức vụ học sinh)
SELECT 
  sp.id,
  s.student_code,
  prof.full_name,
  pos.label as position_name
FROM student_positions sp
JOIN students s ON s.id = sp.student_id
JOIN profiles prof ON prof.id = sp.student_id
JOIN positions pos ON pos.id = sp.position_id
WHERE s.class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
ORDER BY s.student_code;

-- 5. Kiểm tra announcements
SELECT 
  a.id,
  a.title,
  a.content,
  a.created_at,
  a.created_by,
  a.is_pinned,
  p.full_name as author_name,
  p.role as author_role
FROM announcements a
JOIN profiles p ON p.id = a.created_by
WHERE a.class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
ORDER BY a.created_at DESC
LIMIT 5;

-- 6. Test RLS - Kiểm tra policy cho announcements
SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'announcements';

-- 7. Summary
SELECT 
  'Classes' as table_name,
  COUNT(*) as count
FROM classes
WHERE name = '12A2'
UNION ALL
SELECT 'Students', COUNT(*) FROM students WHERE class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
UNION ALL
SELECT 'Groups', COUNT(*) FROM groups WHERE class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1)
UNION ALL
SELECT 'Positions', COUNT(*) FROM positions
UNION ALL
SELECT 'Student Positions', COUNT(*) FROM student_positions
UNION ALL
SELECT 'Announcements', COUNT(*) FROM announcements WHERE class_id = (SELECT id FROM classes WHERE name = '12A2' LIMIT 1);
