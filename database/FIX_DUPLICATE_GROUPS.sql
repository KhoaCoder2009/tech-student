-- ================================================================
-- FIX DUPLICATE GROUPS
-- Xóa các tổ bị duplicate và giữ lại tổ mới nhất
-- ================================================================

-- 1. Kiểm tra tổ bị duplicate
SELECT name, class_id, COUNT(*) as count
FROM groups
GROUP BY name, class_id
HAVING COUNT(*) > 1;

-- 2. Xóa duplicate groups (giữ lại ID nhỏ nhất - tổ cũ nhất)
-- Cẩn thận: script này sẽ xóa data!

DO $$
DECLARE
  v_group_name text;
  v_class_id uuid;
  v_keep_id uuid;
  v_delete_count integer := 0;
BEGIN
  -- Loop through each duplicate group
  FOR v_group_name, v_class_id IN
    SELECT name, class_id
    FROM groups
    GROUP BY name, class_id
    HAVING COUNT(*) > 1
  LOOP
    -- Get the ID to keep (oldest one - smallest ID)
    SELECT id INTO v_keep_id
    FROM groups
    WHERE name = v_group_name AND class_id = v_class_id
    ORDER BY created_at ASC
    LIMIT 1;
    
    RAISE NOTICE 'Keeping group "%" (id: %) for class %', v_group_name, v_keep_id, v_class_id;
    
    -- Update all references to point to the kept group
    UPDATE students
    SET group_id = v_keep_id
    WHERE group_id IN (
      SELECT id FROM groups
      WHERE name = v_group_name 
        AND class_id = v_class_id 
        AND id != v_keep_id
    );
    
    UPDATE student_positions
    SET group_id = v_keep_id
    WHERE group_id IN (
      SELECT id FROM groups
      WHERE name = v_group_name 
        AND class_id = v_class_id 
        AND id != v_keep_id
    );
    
    -- Delete duplicates
    DELETE FROM groups
    WHERE name = v_group_name 
      AND class_id = v_class_id 
      AND id != v_keep_id;
    
    GET DIAGNOSTICS v_delete_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % duplicate groups for "%"', v_delete_count, v_group_name;
  END LOOP;
  
  RAISE NOTICE 'Cleanup complete!';
END $$;

-- 3. Verify no more duplicates
SELECT name, class_id, COUNT(*) as count
FROM groups
GROUP BY name, class_id
HAVING COUNT(*) > 1;

-- Should return 0 rows

-- 4. Add unique constraint to prevent future duplicates
DO $$ BEGIN
  ALTER TABLE groups 
  ADD CONSTRAINT groups_name_class_unique 
  UNIQUE (name, class_id);
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'Constraint already exists';
END $$;

COMMIT;
