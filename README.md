# Tech-Student

Hệ thống quản lý lớp học 12A2 - THPT XYZ

## 📂 Cấu trúc dự án

```
tech-student/
├── admin/                      # Trang quản trị
│   ├── dashboard.html          # Tổng quan
│   ├── students.html           # Quản lý học sinh
│   ├── students-detail.html    # Chi tiết học sinh
│   ├── groups.html             # Quản lý tổ
│   ├── positions.html          # Chức vụ
│   ├── seating.html            # Sơ đồ chỗ ngồi
│   ├── discipline.html         # Nề nếp
│   └── accounts.html           # Tài khoản
├── assets/
│   ├── css/
│   │   └── design-system.css   # Design system
│   ├── js/
│   │   ├── layout.js           # Navigation + Auth
│   │   ├── supabaseClient.js   # Supabase config
│   │   └── ui.js               # Toast, Modal
│   └── img/
│       └── logo.svg
├── services/                   # API Services
│   ├── authService.js
│   ├── studentService.js
│   ├── groupService.js
│   ├── positionService.js
│   ├── disciplineService.js
│   ├── seatingService.js
│   └── accountService.js
├── supabase/
│   ├── schema.sql              # Database schema
│   ├── migrations/
│   │   ├── 001_seating_positions.sql
│   │   ├── 002_ensure_class_and_groups.sql
│   │   ├── 004_attendance_discipline_grades.sql
│   │   ├── 005_announcements.sql
│   │   └── 013_sync_and_cleanup.sql
│   └── functions/
│       └── create-account/
├── login.html
├── unauthorized.html
├── SETUP.sql                   # Script setup database (chạy 1 lần)
└── README.md
```

## 🚀 Cài đặt nhanh

### 1. Cấu hình Supabase

```bash
# Tạo project tại supabase.com
# Trong SQL Editor, chạy theo thứ tự:

1. supabase/schema.sql
2. supabase/migrations/001_seating_positions.sql
3. supabase/migrations/002_ensure_class_and_groups.sql
4. supabase/migrations/004_attendance_discipline_grades.sql
5. supabase/migrations/005_announcements.sql
6. supabase/migrations/013_sync_and_cleanup.sql
7. SETUP.sql  ← Quan trọng! Chạy sau cùng
```

### 2. Cấu hình Frontend

Mở `assets/js/supabaseClient.js` và cập nhật:

```javascript
export const SUPABASE_URL = 'https://kkyiczvvagjkkcsyzanh.supabase.co';
export const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

### 3. Chạy Local Server

```bash
cd tech-student
python -m http.server 5500
```

Mở: `http://localhost:5500/login.html`

## 👥 Tài khoản

**Admin:**
- Email: `admin@techstudent.local`
- Password: `Admin@123`

**Học sinh (40 học sinh):**
- Email: `01@student.techstudent.local` → `40@student.techstudent.local`
- Password: `Student@123`

## 🎯 Phân tổ (theo sơ đồ lớp học chính xác)

**Layout sơ đồ:**
- **5 hàng** từ xa bảng → gần bảng (hàng 5 → hàng 1)
- **4 tổ** theo cột (Tổ 1 trái nhất → Tổ 4 phải nhất)
- **40 học sinh** đúng vị trí như sơ đồ thực tế

**Tổ 1 (10 HS - cột trái):** 04, 05, 08, 19, 20, 21, 23, 30, 35, 36  
**Tổ 2 (10 HS - cột 2):** 13, 17, 22, 24, 27, 29, 31, 37, 39, 40  
**Tổ 3 (10 HS - cột 3):** 01, 03, 07, 10, 11, 12, 16, 26, 34, 38  
**Tổ 4 (10 HS - cột phải):** 02, 06, 09, 14, 15, 18, 25, 28, 32, 33

## ✅ Tính năng

### Quản lý lớp học
- ✅ Học sinh: CRUD, tìm kiếm, filter theo tổ
- ✅ Tổ: Quản lý 4 tổ với màu sắc riêng
- ✅ Chức vụ: Gán chức vụ, tooltip hiển thị tên học sinh
- ✅ Sơ đồ chỗ ngồi: Drag & drop, phân theo tổ

### Nề nếp
- ✅ Cộng/trừ điểm học sinh
- ✅ Lịch sử ghi nhận
- ✅ Bảng điểm tất cả học sinh (như Excel)
- ✅ Top học sinh xuất sắc
- ✅ Danh sách cần chú ý

### Quản lý hệ thống
- ✅ Tài khoản: Quản lý tài khoản admin và học sinh

## 🔒 Phân quyền

- **Admin**: Toàn quyền
- **GVCN**: Quản lý lớp chủ nhiệm
- **Tổ trưởng**: Xem học sinh cùng tổ
- **Học sinh**: Xem dữ liệu bản thân

## 🔧 Troubleshooting

### Lỗi: "Không tìm thấy học sinh"

Chạy trong SQL Editor:
```sql
-- Copy nội dung file QUICK_FIX.sql và chạy
```

### Lỗi: Tổ xuất hiện nhiều lần (duplicate groups)

Chạy trong SQL Editor:
```sql
-- Copy nội dung file FIX_DUPLICATE_GROUPS.sql và chạy
```

### Muốn reset toàn bộ database

⚠️ **CẢNH BÁO:** Sẽ xóa TẤT CẢ dữ liệu!

```sql
-- Copy nội dung file RESET_DATABASE.sql và chạy
-- Sau đó phải import lại 40 học sinh
```

### Lỗi khác

Xem chi tiết trong: `TROUBLESHOOTING.md`

## 📚 Tài liệu

- `SYNC_GUIDE.md` - Hướng dẫn đồng bộ database ↔ frontend
- `TROUBLESHOOTING.md` - Hướng dẫn fix các lỗi thường gặp
- `QUICK_FIX.sql` - Script sửa lỗi nhanh

## 🎨 Tech Stack

- **Frontend**: Vanilla JavaScript (ES6 Modules)
- **Database**: PostgreSQL (Supabase)
- **Auth**: Supabase Auth (JWT)
- **CSS**: Custom Design System
- **Security**: Row Level Security (RLS)

## 📝 Ghi chú

- Database là Single Source of Truth
- Tất cả query đều filter theo lớp 12A2
- RLS đã được bật cho tất cả bảng
- Không sử dụng framework để giữ code đơn giản

---

**Version**: 2.0  
**Last Updated**: 2027  
**Developer**: Tech-Student Team
