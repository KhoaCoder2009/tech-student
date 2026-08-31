-- Migration 002: đảm bảo có 1 trường, lớp 12A2, năm học hiện tại, 4 tổ.
-- An toàn để chạy nhiều lần (idempotent) — sẽ không tạo trùng nếu đã có.
do $$
declare
  v_school_id uuid;
  v_year_id uuid;
  v_class_id uuid;
begin
  select id into v_school_id from schools limit 1;
  if v_school_id is null then
    insert into schools (name) values ('Trường THPT') returning id into v_school_id;
  end if;

  select id into v_year_id from school_years where is_current = true limit 1;
  if v_year_id is null then
    insert into school_years (name, start_date, end_date, is_current)
    values ('2025-2026', '2025-09-05', '2026-05-31', true) returning id into v_year_id;
  end if;

  select id into v_class_id from classes where name = '12A2' limit 1;
  if v_class_id is null then
    insert into classes (school_id, school_year_id, name)
    values (v_school_id, v_year_id, '12A2') returning id into v_class_id;
  end if;

  if not exists (select 1 from groups where class_id = v_class_id) then
    insert into groups (class_id, name, color) values
      (v_class_id, 'Tổ 1', '#4f6df5'),
      (v_class_id, 'Tổ 2', '#22c9a8'),
      (v_class_id, 'Tổ 3', '#f5a524'),
      (v_class_id, 'Tổ 4', '#c05fd6');
  end if;

  raise notice 'class_id = %', v_class_id;
end $$;
