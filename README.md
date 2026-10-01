# tech-student

## Vai trò và phân quyền

Hệ thống có 5 vai trò:

1. **Giáo viên** (`teacher`) - Toàn quyền: xem, chỉnh sửa, tạo tài khoản
2. **Lớp trưởng** (`class_monitor`) - Toàn quyền: xem, chỉnh sửa, tạo tài khoản
3. **Lớp phó học tập** (`academic_monitor`) - Toàn quyền: xem, chỉnh sửa, tạo tài khoản
4. **Bí thư đoàn** (`secretary`) - Toàn quyền: xem, chỉnh sửa, tạo tài khoản
5. **Lớp phó lao động** (`labor_monitor`) - Toàn quyền: xem, chỉnh sửa, tạo tài khoản
6. **Thành viên** (`student`) - Chỉ xem điểm của bản thân, không chỉnh sửa

## Tạo tài khoản học sinh tự động

### Bước 1: Deploy Edge Functions

```bash
# Deploy function tạo tài khoản thông thường
supabase functions deploy create-account

# Deploy function tạo hàng loạt tài khoản học sinh
supabase functions deploy create-student-accounts
```

### Bước 2: Cấu trúc tài khoản học sinh

Tài khoản học sinh được tạo tự động theo công thức:
- **Họ tên**: Trần Đăng Khoa
- **Tài khoản**: `dangkhoa@class.local` (lấy tên riêng, bỏ dấu, viết thường)
- **Mật khẩu**: Giáo viên đặt mật khẩu chung khi tạo (ví dụ: `123456`)

Các ví dụ khác:
- Nguyễn Hoàng Bảo Anh → `baoanh@class.local`
- Hồ Quỳnh Kim Thủy → `kimthuy@class.local`
- Lê Xuân Nhật Huy → `huy@class.local`

### Bước 3: Tạo tài khoản hàng loạt

1. Đăng nhập với tài khoản **Giáo viên** hoặc **Lớp trưởng** hoặc **Lớp phó** hoặc **Bí thư**
2. Mở trang `manage-students.html`
3. Nhập mật khẩu mặc định (ví dụ: `123456`)
4. Nhấn **"Tạo tài khoản hàng loạt"**
5. Hệ thống sẽ tự động:
   - Tạo tài khoản cho tất cả học sinh chưa có tài khoản
   - Tạo email theo tên riêng
   - Gán role `student`
   - Liên kết với mã học sinh (HS001, HS002...)
6. Tải xuống file CSV hoặc sao chép danh sách để phát cho học sinh

### Bước 4: Học sinh đăng nhập

1. Mở trang `login.html`
2. Nhập:
   - **Tài khoản**: `dangkhoa@class.local`
   - **Mật khẩu**: `123456` (hoặc mật khẩu giáo viên đã đặt)
3. Sau khi đăng nhập, tự động chuyển sang `student-view.html` để xem điểm

## Đăng nhập và tạo tài khoản quản lý

- Mở `login.html` để đăng nhập
- `index.html` sẽ tự chuyển hướng sang trang đăng nhập nếu chưa có phiên
- Nút `Tạo tài khoản` chỉ xuất hiện với 5 vai trò quản lý (teacher, class_monitor, academic_monitor, secretary, labor_monitor)
- Edge Function `supabase/functions/create-account/index.ts` kiểm tra vai trò ở server trước khi tạo tài khoản Auth và hồ sơ `profiles`

Function sử dụng các biến môi trường mặc định của Supabase, bao gồm `SUPABASE_URL`, `SUPABASE_ANON_KEY` và `SUPABASE_SERVICE_ROLE_KEY`. Không đưa service role key vào HTML hoặc JavaScript phía trình duyệt.

## Cơ sở dữ liệu

### Bảng `students`
- `student_id`: Mã học sinh (HS001, HS002...)
- `name`: Họ tên học sinh
- `has_account`: Đã tạo tài khoản chưa

### Bảng `profiles`
- `role`: teacher, class_monitor, academic_monitor, secretary, labor_monitor, student
- `student_id`: Liên kết với bảng students (nếu là student)

## Lưu ý bảo mật

- Service Role Key chỉ dùng trong Edge Functions
- Row Level Security đã được bật
- Học sinh chỉ xem được điểm của chính mình

