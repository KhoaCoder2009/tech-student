-- ============================================================
-- TECH-STUDENT · DATABASE SCHEMA + ROW LEVEL SECURITY
-- Khớp chính xác với tên bảng/cột mà services/*.js đang truy vấn.
-- Chạy toàn bộ file này trong Supabase SQL Editor trên project mới.
-- ============================================================

-- ---------- danh mục lõi (không hard-code ở frontend) ----------

create table school_years (
  id uuid primary key default gen_random_uuid(),
  name text not null,                 -- '2025-2026'
  start_date date not null,
  end_date date not null,
  is_current boolean not null default false,
  created_at timestamptz default now()
);

create table schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);

create table classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools(id) on delete cascade,
  school_year_id uuid references school_years(id) on delete cascade,
  name text not null,                 -- '12A2'
  created_at timestamptz default now()
);

create table groups (                 -- "Tổ"
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,
  name text not null,                 -- 'Tổ 1'
  color text not null default '#4f6df5',
  created_at timestamptz default now()
);

create table positions (              -- danh mục chức vụ, mở rộng được
  id uuid primary key default gen_random_uuid(),
  code text unique not null,          -- 'to_truong'
  label text not null,                -- 'Tổ trưởng'
  scope text not null default 'group' check (scope in ('class','group','none')),
  created_at timestamptz default now()
);

-- ---------- người dùng & vai trò ----------

create type user_role as enum ('admin','teacher','student');

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'student',
  full_name text not null,
  email text,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz default now()
);

create table teachers (
  id uuid primary key references profiles(id) on delete cascade,
  teacher_type text not null default 'subject' check (teacher_type in ('gvcn','subject','admin_staff')),
  homeroom_class_id uuid references classes(id)
);

create table students (
  id uuid primary key references profiles(id) on delete cascade,
  class_id uuid references classes(id),
  group_id uuid references groups(id),
  student_code text unique not null,
  dob date,
  gender text,
  discipline_score numeric(5,1) default 85.0,
  attendance_rate numeric(5,1) default 95.0,
  national_id text,
  address text,
  phone text,
  parent_father_name text,
  parent_father_phone text,
  parent_mother_name text,
  parent_mother_phone text,
  parent_occupation text,
  notes text
);

create table student_positions (      -- 1 học sinh có thể có 1+ chức vụ, theo phạm vi group + năm học
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  position_id uuid references positions(id),
  group_id uuid references groups(id),
  school_year_id uuid references school_years(id),
  created_at timestamptz default now()
);

-- ---------- sơ đồ chỗ ngồi ----------

create table seating_positions (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,
  group_id uuid references groups(id) on delete cascade,
  student_id uuid references students(id) on delete cascade unique,
  seat_row int not null,
  seat_col int not null,
  school_year_id uuid references school_years(id),
  created_at timestamptz default now(),
  unique (group_id, seat_row, seat_col)
);

-- ---------- quyền chi tiết: role + position + scope ----------

create table permissions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  label text not null
);

create table role_permissions (
  id uuid primary key default gen_random_uuid(),
  role user_role,
  position_id uuid references positions(id),
  permission_id uuid references permissions(id),
  scope text not null default 'own_group' check (scope in ('class','own_group','self'))
);

-- ---------- hàm hỗ trợ RLS ----------

create or replace function current_role_is(target_role user_role)
returns boolean language sql stable as $$
  select exists(select 1 from profiles where id = auth.uid() and role = target_role and is_active);
$$;

create or replace function is_gvcn_of(target_class_id uuid)
returns boolean language sql stable as $$
  select exists(
    select 1 from teachers t join profiles p on p.id = t.id
    where t.id = auth.uid() and t.teacher_type = 'gvcn' and t.homeroom_class_id = target_class_id and p.is_active
  );
$$;

-- ---------- bật RLS ----------

alter table profiles enable row level security;
alter table students enable row level security;
alter table student_positions enable row level security;
alter table teachers enable row level security;
alter table groups enable row level security;
alter table positions enable row level security;
alter table school_years enable row level security;
alter table seating_positions enable row level security;

-- profiles: mọi người dùng đã đăng nhập đọc được profile của chính mình;
-- Admin đọc/ghi toàn bộ.
create policy self_read_profile on profiles for select using (id = auth.uid());
create policy admin_full_profiles on profiles for all
  using (current_role_is('admin')) with check (current_role_is('admin'));

-- groups / positions / school_years: mọi người dùng đã đăng nhập đều đọc được
-- (đây là danh mục dùng chung để hiển thị UI), chỉ Admin sửa được.
create policy read_groups on groups for select using (auth.uid() is not null);
create policy admin_write_groups on groups for insert with check (current_role_is('admin'));
create policy admin_update_groups on groups for update using (current_role_is('admin'));

create policy read_positions on positions for select using (auth.uid() is not null);
create policy admin_write_positions on positions for all
  using (current_role_is('admin')) with check (current_role_is('admin'));

create policy read_school_years on school_years for select using (auth.uid() is not null);
create policy admin_write_school_years on school_years for all
  using (current_role_is('admin')) with check (current_role_is('admin'));

-- students: Admin toàn quyền.
create policy admin_full_students on students for all
  using (current_role_is('admin')) with check (current_role_is('admin'));

-- GVCN: đọc/sửa học sinh trong lớp mình chủ nhiệm.
create policy gvcn_read_class_students on students for select using (is_gvcn_of(class_id));
create policy gvcn_update_class_students on students for update using (is_gvcn_of(class_id)) with check (is_gvcn_of(class_id));

-- Học sinh: đọc học sinh cùng lớp (hồ sơ công khai — cột nhạy cảm nên tách bảng riêng, xem dưới),
-- chỉ sửa được vài trường của chính mình.
create policy student_read_own_class on students for select using (
  current_role_is('student') and class_id = (select class_id from students where id = auth.uid())
);
create policy student_update_self on students for update using (id = auth.uid()) with check (id = auth.uid());

-- Tổ trưởng / Phó tổ trưởng: chỉ đọc học sinh CÙNG group_id với phạm vi được giao,
-- không đọc được các tổ khác dù đổi id trên URL — vì RLS so khớp ở tầng database.
create policy group_leader_read_own_group on students for select using (
  exists (
    select 1 from student_positions sp join positions pos on pos.id = sp.position_id
    where sp.student_id = auth.uid()
      and pos.code in ('to_truong','pho_to_truong')
      and sp.group_id = students.group_id
  )
);

-- student_positions: đọc theo lớp; ghi chỉ Admin/GVCN.
create policy read_student_positions on student_positions for select using (auth.uid() is not null);
create policy admin_gvcn_write_positions on student_positions for all using (
  current_role_is('admin') or exists (
    select 1 from students s where s.id = student_positions.student_id and is_gvcn_of(s.class_id)
  )
);

-- seating_positions: mọi người đã đăng nhập đọc được; chỉ Admin/GVCN của lớp đó ghi.
create policy read_seating on seating_positions for select using (auth.uid() is not null);
create policy admin_gvcn_write_seating on seating_positions for all using (
  current_role_is('admin') or exists (
    select 1 from classes c where c.id = seating_positions.class_id and is_gvcn_of(c.id)
  )
);

-- ---------- bảng dữ liệu nhạy cảm tách riêng ----------
-- CCCD / SĐT phụ huynh / địa chỉ chỉ Admin và GVCN của lớp đó đọc được —
-- học sinh (kể cả tổ trưởng) không bao giờ thấy dữ liệu này của người khác.

create table student_sensitive_info (
  student_id uuid primary key references students(id) on delete cascade,
  national_id text,
  parent_father_phone text,
  parent_mother_phone text,
  address text
);
alter table student_sensitive_info enable row level security;
create policy sensitive_admin_gvcn_only on student_sensitive_info for select using (
  current_role_is('admin') or is_gvcn_of((select class_id from students where id = student_sensitive_info.student_id))
);

-- ============================================================
-- SEED DANH MỤC TỐI THIỂU (không seed học sinh mẫu — dữ liệu thật
-- do Admin nhập qua trang Tài khoản / Học sinh sau khi triển khai).
-- ============================================================
insert into positions (code, label, scope) values
  ('thanh_vien','Thành viên','group'),
  ('lop_truong','Lớp trưởng','class'),
  ('lop_pho_hoc_tap','Lớp phó học tập','class'),
  ('lop_pho','Lớp phó','class'),
  ('bi_thu','Bí thư','class'),
  ('to_truong','Tổ trưởng','group'),
  ('pho_to_truong','Phó tổ trưởng','group');

insert into school_years (name, start_date, end_date, is_current) values
  ('2025-2026', '2025-09-05', '2026-05-31', true);
