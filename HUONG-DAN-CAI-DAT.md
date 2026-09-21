# 🚀 HƯỚNG DẪN CÀI ĐẶT VÀ SỬ DỤNG

## 📋 Các vai trò trong hệ thống

| Vai trò | Quyền hạn | Mô tả |
|---------|-----------|-------|
| **Giáo viên** | ✅ Toàn quyền | Xem, chỉnh sửa, tạo tài khoản |
| **Lớp trưởng** | ✅ Toàn quyền | Xem, chỉnh sửa, tạo tài khoản |
| **Lớp phó học tập** | ✅ Toàn quyền | Xem, chỉnh sửa, tạo tài khoản |
| **Bí thư đoàn** | ✅ Toàn quyền | Xem, chỉnh sửa, tạo tài khoản |
| **Thành viên** | 👀 Chỉ xem | Chỉ xem điểm của bản thân |

---

## 🔧 Bước 1: Cài đặt database (Supabase SQL Editor)

```sql
-- Chạy file supabase-schema.sql trong Supabase SQL Editor
-- File này sẽ tạo:
-- ✅ Bảng profiles với 5 vai trò
-- ✅ Bảng students với student_id
-- ✅ Bảng class_settings, violation_types, violation_records
-- ✅ Row Level Security policies
```

---

## 🚀 Bước 2: Deploy Edge Functions

```bash
# Cài đặt Supabase CLI nếu chưa có
npm install -g supabase

# Deploy function tạo tài khoản thông thường
supabase functions deploy create-account

# Deploy function tạo hàng loạt tài khoản học sinh
supabase functions deploy create-student-accounts
```

---

## 👨‍🏫 Bước 3: Tạo tài khoản ban quản lý đầu tiên

### Cách 1: Tạo trong Supabase Dashboard
1. Vào **Authentication** → **Users** → **Add user**
2. Nhập email và password
3. Vào **SQL Editor**, chạy:

```sql
-- Thay 'email@example.com' bằng email thực tế
INSERT INTO public.profiles (id, display_name, role, class_id)
SELECT id, 'Tên Giáo Viên', 'teacher', 'main'
FROM auth.users
WHERE email = 'giaovien@example.com';
```

### Cách 2: Sửa trong file `supabase-schema.sql`
Sửa 3 câu INSERT cuối file với email thực tế:

```sql
INSERT INTO public.profiles (id, display_name, role)
SELECT id, 'Cô Tú Anh', 'teacher'
FROM auth.users
WHERE email = 'tuanh@school.edu.vn';

INSERT INTO public.profiles (id, display_name, role)
SELECT id, 'Trần Đăng Khoa', 'class_monitor'
FROM auth.users
WHERE email = 'dangkhoa@school.edu.vn';

INSERT INTO public.profiles (id, display_name, role)
SELECT id, 'Hồ Quỳnh Kim Thủy', 'academic_monitor'
FROM auth.users
WHERE email = 'kimthuy@school.edu.vn';

INSERT INTO public.profiles (id, display_name, role)
SELECT id, 'Nguyễn Văn A', 'secretary'
FROM auth.users
WHERE email = 'secretary@school.edu.vn';
```

---

## 👥 Bước 4: Tạo tài khoản học sinh hàng loạt

### 4.1. Đăng nhập
- Mở `login.html` với tài khoản **Giáo viên/Lớp trưởng/Lớp phó/Bí thư**

### 4.2. Tạo tài khoản hàng loạt
1. Nhấn nút **"👥 TK học sinh"** trong sidebar
2. Hoặc mở trực tiếp: `manage-students.html`
3. Nhập mật khẩu mặc định (ví dụ: `123456`)
4. Nhấn **"🚀 Tạo tài khoản hàng loạt"**

### 4.3. Cấu trúc tài khoản
Hệ thống tự động tạo tài khoản theo công thức:

| Họ tên | Tài khoản | Mật khẩu |
|--------|-----------|----------|
| Trần Đăng Khoa | `dangkhoa@class.local` | `123456` |
| Nguyễn Hoàng Bảo Anh | `baoanh@class.local` | `123456` |
| Hồ Quỳnh Kim Thủy | `kimthuy@class.local` | `123456` |

**Quy tắc**: Lấy **tên riêng** → bỏ dấu → viết thường → `@class.local`

### 4.4. Phát tài khoản cho học sinh
- Nhấn **"📋 Sao chép toàn bộ"** để copy danh sách
- Hoặc **"💾 Tải xuống CSV"** để lưu file Excel

---

## 📱 Bước 5: Học sinh sử dụng

### Đăng nhập
1. Mở `login.html`
2. Nhập:
   - **Tài khoản**: `dangkhoa@class.local`
   - **Mật khẩu**: `123456`
3. Hệ thống tự động chuyển sang trang xem điểm

### Xem điểm
- Trang `student-view.html` hiển thị:
  - 📊 Tổng số lượt ghi nhận
  - ✅ Điểm cộng
  - ❌ Điểm trừ
  - 📈 Tổng điểm
  - 📜 Lịch sử chi tiết từng lần vi phạm/khen thưởng

---

## 🎯 Bước 6: Ban quản lý sử dụng

### Đăng nhập
1. Mở `login.html`
2. Nhập tài khoản của **Giáo viên/Lớp trưởng/Lớp phó/Bí thư**
3. Tự động vào trang chính `index.html`

### Ghi nhận vi phạm
1. Chọn tuần (nút ◀ ▶)
2. Tab **"Sổ ghi nhận"**:
   - Nhấn **"+ Thêm dòng"**
   - Chọn **Vi phạm** → Tự động điền điểm
   - Chọn **Học sinh**
   - Chọn **Ngày, buổi**
   - Ghi **Chú thích** (nếu có)
3. Hệ thống tự động lưu

### Xem báo cáo
- **Dashboard**: Thống kê tổng quan
- **Biểu đồ xu hướng**: Theo tuần/tháng
- **Xếp hạng**: Top 5 học sinh
- **Bảng tổng hợp**: Ma trận học sinh × vi phạm

### Xuất Excel
- Nhấn **"↓ Xuất Excel"**
- Chọn:
  - **Tuần đang xem**: Chỉ tuần hiện tại
  - **Tất cả các tuần**: Toàn bộ năm học

---

## ⚙️ Cài đặt nâng cao

### Thêm/Sửa danh mục lỗi
1. Nhấn nút **⚙ Cài đặt**
2. Phần **"Danh mục lỗi và điểm"**:
   - Sửa tên lỗi
   - Thay đổi điểm trừ/cộng
   - Thêm lỗi mới
3. Nhấn **"Xong"**

### Quản lý danh sách lớp
1. Nhấn nút **⚙ Cài đặt**
2. Nhập danh sách học sinh (mỗi dòng một em)
3. Hoặc **"Nhập từ Excel"** (cột "Họ và tên")
4. Nhấn **"Xong"**

---

## 🔒 Bảo mật

✅ **Row Level Security** đã bật
✅ Học sinh chỉ xem được điểm của mình
✅ Service Role Key chỉ dùng trong Edge Functions
✅ Không lộ thông tin nhạy cảm ra client

---

## 📞 Hỗ trợ

Nếu có vấn đề:
1. Kiểm tra console browser (F12)
2. Kiểm tra Supabase logs
3. Đảm bảo đã deploy đủ 2 Edge Functions
4. Kiểm tra roles trong database

---

**🎉 Chúc bạn sử dụng thành công!**
