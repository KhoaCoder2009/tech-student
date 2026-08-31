-- Migration 001: bảng sơ đồ chỗ ngồi.
-- Chạy trong Supabase SQL Editor (chỉ cần chạy 1 lần trên project đã có schema.sql).
create table if not exists seating_positions (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,
  group_id uuid references groups(id) on delete cascade,
  student_id uuid references students(id) on delete cascade unique,
  seat_row int not null,
  seat_col int not null,
  school_year_id uuid references school_years(id),
  created_at timestamptz default now(),
  unique (group_id, seat_row, seat_col)  -- toạ độ ghế là duy nhất TRONG PHẠM VI 1 TỔ
);
alter table seating_positions enable row level security;

create policy read_seating on seating_positions for select using (auth.uid() is not null);
create policy admin_gvcn_write_seating on seating_positions for all using (
  current_role_is('admin') or exists (
    select 1 from classes c where c.id = seating_positions.class_id and is_gvcn_of(c.id)
  )
);
