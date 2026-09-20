-- Chay trong Supabase SQL Editor.
-- Tao ba tai khoan trong Authentication truoc, sau do gan id vao profiles.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  role text not null check (role in ('teacher', 'class_monitor', 'academic_monitor'))
);

create table if not exists public.class_settings (
  class_id text primary key,
  class_name text not null default ''
);

create table if not exists public.students (
  class_id text not null,
  name text not null,
  sort_order integer not null default 0,
  primary key (class_id, name)
);

create table if not exists public.violation_types (
  id text not null,
  class_id text not null,
  group_id text not null,
  name text not null,
  short_name text not null,
  points integer not null default 0,
  sort_order integer not null default 0,
  primary key (class_id, id)
);

create table if not exists public.violation_records (
  id text primary key,
  class_id text not null,
  week_start date not null,
  violation_type_id text not null,
  violation_name text not null,
  group_id text not null,
  points integer not null default 0,
  student_name text not null default '',
  occurred_on date not null,
  session text not null default 'Sang',
  note text not null default '',
  recorded_by uuid not null references public.profiles(id),
  recorded_by_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists violation_records_week_idx
  on public.violation_records (class_id, week_start);

alter table public.profiles enable row level security;
alter table public.class_settings enable row level security;
alter table public.students enable row level security;
alter table public.violation_types enable row level security;
alter table public.violation_records enable row level security;

create policy "signed in users can read profiles"
  on public.profiles for select to authenticated using (true);
create policy "signed in users can read class settings"
  on public.class_settings for select to authenticated using (true);
create policy "signed in users can write class settings"
  on public.class_settings for all to authenticated using (true) with check (true);
create policy "signed in users can manage students"
  on public.students for all to authenticated using (true) with check (true);
create policy "signed in users can manage violation types"
  on public.violation_types for all to authenticated using (true) with check (true);
create policy "signed in users can manage records"
  on public.violation_records for all to authenticated using (true) with check (true);

insert into public.class_settings (class_id, class_name)
values ('main', '')
on conflict (class_id) do nothing;

insert into public.students (class_id, name, sort_order) values
  ('main', 'Nguyễn Quốc An', 1),
  ('main', 'Nguyễn Hoàng Bảo Anh', 2),
  ('main', 'Huỳnh Minh Ánh', 3),
  ('main', 'Nguyễn Bảo Châu', 4),
  ('main', 'Nguyễn Ngọc Minh Châu', 5),
  ('main', 'Nguyễn Thị Mỹ Duyên', 6),
  ('main', 'Nguyễn Thị Anh Đào', 7),
  ('main', 'Trần Tiến Đạt', 8),
  ('main', 'Võ Thanh Giang', 9),
  ('main', 'Nguyễn Hoàng Hải', 10),
  ('main', 'Mai Gia Hân', 11),
  ('main', 'Bùi Quốc Huy', 12),
  ('main', 'Lê Xuân Nhật Huy', 13),
  ('main', 'Lê Nguyễn Đăng Khoa', 14),
  ('main', 'Trần Đăng Khoa', 15),
  ('main', 'Nguyễn Thị Xuân Linh', 16),
  ('main', 'Phạm Tấn Lực', 17),
  ('main', 'Trần Thị Ngọc My', 18),
  ('main', 'Nguyễn Trung Nghĩa', 19),
  ('main', 'Mai Như Ngọc', 20),
  ('main', 'Võ Hữu Ngọc', 21),
  ('main', 'Nguyễn Thị Thu Nguyệt', 22),
  ('main', 'Nguyễn Thanh Tuyết Nhi', 23),
  ('main', 'Lâm Tâm Như', 24),
  ('main', 'Dương Chấn Phong', 25),
  ('main', 'Lâm Thiên Phúc', 26),
  ('main', 'Từ Thị Mai Phương', 27),
  ('main', 'Nguyễn Hoàng Sơn', 28),
  ('main', 'Nguyễn Minh Tâm', 29),
  ('main', 'Nguyễn Hoàng Thái', 30),
  ('main', 'Trịnh Minh Thiên', 31),
  ('main', 'Trần Thị Ngọc Thùy', 32),
  ('main', 'Hồ Quỳnh Kim Thủy', 33),
  ('main', 'Phạm Thị Ngọc Trâm', 34),
  ('main', 'Quách Thị Thanh Tuyền', 35),
  ('main', 'Trần Minh Tướng', 36),
  ('main', 'Nguyễn Thị Vi', 37),
  ('main', 'Đinh Thị Yến Vy', 38),
  ('main', 'Mai Phương Vy', 39),
  ('main', 'Trần Trúc Vy', 40)
on conflict (class_id, name) do update set sort_order = excluded.sort_order;

-- Tao 3 user trong Authentication truoc, sau do thay 3 email ben duoi
-- bang email thuc te va chay khoi lenh nay de gan vai tro.
insert into public.profiles (id, display_name, role)
select id, 'Trần Đăng Khoa', 'class_monitor'
from auth.users
where email = 'dangkhoa@edu.vn'
on conflict (id) do update set display_name = excluded.display_name, role = excluded.role;

insert into public.profiles (id, display_name, role)
select id, 'Tú Anh', 'teacher'
from auth.users
where email = 'tuanh@edu.vn'
on conflict (id) do update set display_name = excluded.display_name, role = excluded.role;

insert into public.profiles (id, display_name, role)
select id, 'Hồ Quỳnh Kim Thủy', 'academic_monitor'
from auth.users
where email = 'kimthuy@edu.vn'
on conflict (id) do update set display_name = excluded.display_name, role = excluded.role;
