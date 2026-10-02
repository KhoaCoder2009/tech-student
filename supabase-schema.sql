-- Chay trong Supabase SQL Editor.
-- Tao cac tai khoan trong Authentication truoc, sau do gan role vao profiles.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  role text not null check (role in ('teacher', 'class_monitor', 'academic_monitor', 'secretary', 'labor_monitor', 'student'))
);

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('teacher', 'class_monitor', 'academic_monitor', 'secretary', 'labor_monitor', 'student'));

create table if not exists public.class_settings (
  class_id text primary key,
  class_name text not null default ''
);

create table if not exists public.students (
  class_id text not null,
  name text not null,
  sort_order integer not null default 0,
  base_points integer not null default 100,
  current_points integer not null default 100,
  primary key (class_id, name)
);

alter table public.students
  add column if not exists sort_order integer not null default 0,
  add column if not exists base_points integer not null default 100,
  add column if not exists current_points integer not null default 100;

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

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.role from public.profiles as p where p.id = auth.uid()
$$;

create or replace function public.current_app_display_name()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.display_name from public.profiles as p where p.id = auth.uid()
$$;

revoke all on function public.current_app_role() from public;
revoke all on function public.current_app_display_name() from public;
grant execute on function public.current_app_role() to authenticated;
grant execute on function public.current_app_display_name() to authenticated;

drop policy if exists "signed in users can read profiles" on public.profiles;
create policy "signed in users can read profiles"
  on public.profiles for select to authenticated using (true);

drop policy if exists "signed in users can read class settings" on public.class_settings;
drop policy if exists "signed in users can write class settings" on public.class_settings;
drop policy if exists "managers can manage class settings" on public.class_settings;
drop policy if exists "recorders can read class settings" on public.class_settings;
drop policy if exists "duty staff can read class settings" on public.class_settings;
create policy "managers can manage class settings"
  on public.class_settings for all to authenticated
  using (public.current_app_role() in ('teacher', 'class_monitor', 'secretary'))
  with check (public.current_app_role() in ('teacher', 'class_monitor', 'secretary'));
create policy "recorders can read class settings"
  on public.class_settings for select to authenticated
  using (public.current_app_role() = 'academic_monitor');
create policy "duty staff can read class settings"
  on public.class_settings for select to authenticated
  using (public.current_app_role() = 'labor_monitor');

drop policy if exists "signed in users can manage students" on public.students;
drop policy if exists "managers can manage students" on public.students;
drop policy if exists "recorders can read students" on public.students;
drop policy if exists "duty staff can read students" on public.students;
create policy "managers can manage students"
  on public.students for all to authenticated
  using (public.current_app_role() in ('teacher', 'class_monitor', 'secretary'))
  with check (public.current_app_role() in ('teacher', 'class_monitor', 'secretary'));
create policy "recorders can read students"
  on public.students for select to authenticated
  using (public.current_app_role() = 'academic_monitor');
create policy "duty staff can read students"
  on public.students for select to authenticated
  using (public.current_app_role() = 'labor_monitor');

drop policy if exists "signed in users can manage violation types" on public.violation_types;
drop policy if exists "managers can manage violation types" on public.violation_types;
drop policy if exists "recorders can read violation types" on public.violation_types;
drop policy if exists "duty staff can read violation types" on public.violation_types;
create policy "managers can manage violation types"
  on public.violation_types for all to authenticated
  using (public.current_app_role() in ('teacher', 'class_monitor', 'secretary'))
  with check (public.current_app_role() in ('teacher', 'class_monitor', 'secretary'));
create policy "recorders can read violation types"
  on public.violation_types for select to authenticated
  using (public.current_app_role() = 'academic_monitor');
create policy "duty staff can read violation types"
  on public.violation_types for select to authenticated
  using (public.current_app_role() = 'labor_monitor');

drop policy if exists "signed in users can manage records" on public.violation_records;
drop policy if exists "recorders can manage violation records" on public.violation_records;
drop policy if exists "authorized users can read violation records" on public.violation_records;
create policy "recorders can manage violation records"
  on public.violation_records for all to authenticated
  using (public.current_app_role() in ('teacher', 'class_monitor', 'secretary', 'academic_monitor'))
  with check (public.current_app_role() in ('teacher', 'class_monitor', 'secretary', 'academic_monitor'));
create policy "authorized users can read violation records"
  on public.violation_records for select to authenticated
  using (
    public.current_app_role() in ('labor_monitor', 'teacher', 'class_monitor', 'secretary', 'academic_monitor')
    or (
      public.current_app_role() = 'student'
      and student_name = public.current_app_display_name()
    )
  );

insert into public.class_settings (class_id, class_name)
values ('main', '')
on conflict (class_id) do nothing;

insert into public.students (class_id, name, sort_order, base_points, current_points) values
  ('main', 'Nguyễn Quốc An', 1, 100, 100),
  ('main', 'Nguyễn Hoàng Bảo Anh', 2, 100, 100),
  ('main', 'Huỳnh Minh Ánh', 3, 100, 100),
  ('main', 'Nguyễn Bảo Châu', 4, 100, 100),
  ('main', 'Nguyễn Ngọc Minh Châu', 5, 100, 100),
  ('main', 'Nguyễn Thị Mỹ Duyên', 6, 100, 100),
  ('main', 'Nguyễn Thị Anh Đào', 7, 100, 100),
  ('main', 'Trần Tiến Đạt', 8, 100, 100),
  ('main', 'Võ Thanh Giang', 9, 100, 100),
  ('main', 'Nguyễn Hoàng Hải', 10, 100, 100),
  ('main', 'Mai Gia Hân', 11, 100, 100),
  ('main', 'Bùi Quốc Huy', 12, 100, 100),
  ('main', 'Lê Xuân Nhật Huy', 13, 100, 100),
  ('main', 'Lê Nguyễn Đăng Khoa', 14, 100, 100),
  ('main', 'Trần Đăng Khoa', 15, 100, 100),
  ('main', 'Nguyễn Thị Xuân Linh', 16, 100, 100),
  ('main', 'Phạm Tấn Lực', 17, 100, 100),
  ('main', 'Trần Thị Ngọc My', 18, 100, 100),
  ('main', 'Nguyễn Trung Nghĩa', 19, 100, 100),
  ('main', 'Mai Như Ngọc', 20, 100, 100),
  ('main', 'Võ Hữu Ngọc', 21, 100, 100),
  ('main', 'Nguyễn Thị Thu Nguyệt', 22, 100, 100),
  ('main', 'Nguyễn Thanh Tuyết Nhi', 23, 100, 100),
  ('main', 'Lâm Tâm Như', 24, 100, 100),
  ('main', 'Dương Chấn Phong', 25, 100, 100),
  ('main', 'Lâm Thiên Phúc', 26, 100, 100),
  ('main', 'Từ Thị Mai Phương', 27, 100, 100),
  ('main', 'Nguyễn Hoàng Sơn', 28, 100, 100),
  ('main', 'Nguyễn Minh Tâm', 29, 100, 100),
  ('main', 'Nguyễn Hoàng Thái', 30, 100, 100),
  ('main', 'Trịnh Minh Thiên', 31, 100, 100),
  ('main', 'Trần Thị Ngọc Thùy', 32, 100, 100),
  ('main', 'Hồ Quỳnh Kim Thủy', 33, 100, 100),
  ('main', 'Phạm Thị Ngọc Trâm', 34, 100, 100),
  ('main', 'Quách Thị Thanh Tuyền', 35, 100, 100),
  ('main', 'Trần Minh Tướng', 36, 100, 100),
  ('main', 'Nguyễn Thị Vi', 37, 100, 100),
  ('main', 'Đinh Thị Yến Vy', 38, 100, 100),
  ('main', 'Mai Phương Vy', 39, 100, 100),
  ('main', 'Trần Trúc Vy', 40, 100, 100)
on conflict (class_id, name) do update set sort_order = excluded.sort_order;

-- Function tự động cập nhật điểm học sinh
create or replace function update_student_points()
returns trigger as $$
declare
  student_total integer;
begin
  -- Tính tổng điểm của học sinh
  select coalesce(sum(points), 0) into student_total
  from violation_records
  where class_id = coalesce(NEW.class_id, OLD.class_id)
    and student_name = coalesce(NEW.student_name, OLD.student_name);
  
  -- Cập nhật current_points = 100 + tổng điểm (tối thiểu 0)
  update students
  set current_points = greatest(0, 100 + student_total)
  where class_id = coalesce(NEW.class_id, OLD.class_id)
    and name = coalesce(NEW.student_name, OLD.student_name);
  
  return coalesce(NEW, OLD);
end;
$$ language plpgsql;

-- Trigger khi thêm/sửa/xóa violation_records
drop trigger if exists update_points_on_insert on violation_records;
create trigger update_points_on_insert
  after insert on violation_records
  for each row
  execute function update_student_points();

drop trigger if exists update_points_on_update on violation_records;
create trigger update_points_on_update
  after update on violation_records
  for each row
  execute function update_student_points();

drop trigger if exists update_points_on_delete on violation_records;
create trigger update_points_on_delete
  after delete on violation_records
  for each row
  execute function update_student_points();

-- Tao user trong Authentication truoc, sau do chay cac lenh ben duoi
-- de gan vai tro cho profile.
-- Chay migration nay ca khi bang profiles da ton tai tu truoc.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('teacher', 'class_monitor', 'academic_monitor', 'secretary', 'labor_monitor', 'student'));

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

insert into public.profiles (id, display_name, role)
select id, 'Nguyễn Thị Anh Đào', 'secretary'
from auth.users
where email = 'anhdao@edu.vn'
on conflict (id) do update set display_name = excluded.display_name, role = excluded.role;

insert into public.profiles (id, display_name, role)
select id, 'Phạm Tấn Lực', 'labor_monitor'
from auth.users
where email = 'tanluc@edu.vn'
on conflict (id) do update set display_name = excluded.display_name, role = excluded.role;

-- Duty schedules table (Bảng phân công trực nhật)
create table if not exists public.duty_schedules (
  week_start date primary key,
  schedule jsonb not null,
  updated_at timestamptz not null default now()
);

-- Nhat ky thao tac hien thi trong icon thong bao.
create table if not exists public.activity_logs (
  id bigint generated by default as identity primary key,
  class_id text not null default 'main',
  actor_id uuid not null references public.profiles(id),
  actor_name text not null,
  actor_role text not null,
  action text not null,
  details text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists activity_logs_created_at_idx
  on public.activity_logs (class_id, created_at desc);

alter table public.activity_logs enable row level security;

drop policy if exists "signed in users can read activity logs" on public.activity_logs;
drop policy if exists "authorized roles can read activity logs" on public.activity_logs;
create policy "authorized roles can read activity logs"
  on public.activity_logs for select to authenticated
  using (
    public.current_app_role() in ('teacher', 'class_monitor', 'secretary')
    or (public.current_app_role() = 'academic_monitor' and action in ('Sửa ghi nhận', 'Xóa ghi nhận', 'Ghi nhận hàng loạt'))
    or (public.current_app_role() = 'labor_monitor' and action = 'Lưu phân công trực nhật')
  );
drop policy if exists "signed in users can write activity logs" on public.activity_logs;
create policy "signed in users can write activity logs"
  on public.activity_logs for insert to authenticated with check (auth.uid() = actor_id);

alter table public.duty_schedules enable row level security;

drop policy if exists "signed in users can manage duty schedules" on public.duty_schedules;
drop policy if exists "authorized staff can manage duty schedules" on public.duty_schedules;
create policy "authorized staff can manage duty schedules"
  on public.duty_schedules for all to authenticated
  using (public.current_app_role() in ('teacher', 'class_monitor', 'secretary', 'labor_monitor'))
  with check (public.current_app_role() in ('teacher', 'class_monitor', 'secretary', 'labor_monitor'));
