# 🎓 Tech-Student

Hệ thống quản lý học sinh và điểm nề nếp cho lớp học.

## 📁 Cấu trúc project

```
tech-student/
├── admin/              # Trang quản trị (Admin Dashboard)
│   ├── dashboard.html  # Trang chủ admin
│   ├── students.html   # Quản lý học sinh
│   ├── groups.html     # Quản lý tổ học tập
│   ├── positions.html  # Quản lý chức vụ
│   ├── discipline.html # Ghi nhận vi phạm
│   ├── announcements.html # Thông báo lớp học
│   └── accounts.html   # Quản lý tài khoản
│
├── student/            # Trang dành cho học sinh
│   ├── home.html       # Trang chủ học sinh
│   ├── friends.html    # Danh sách bạn bè
│   ├── mygroup.html    # Tổ của tôi
│   ├── discipline.html # Điểm nề nếp cá nhân
│   ├── announcements.html # Xem thông báo
│   └── profile.html    # Hồ sơ cá nhân
│
├── assets/
│   ├── css/
│   │   └── design-system.css  # Design system toàn project
│   └── js/
│       ├── supabaseClient.js  # Supabase client config
│       ├── adminLayout.js     # Layout cho admin
│       ├── studentLayout.js   # Layout cho student
│       └── ui.js             # UI components (toast, modal, etc)
│
├── services/           # API service layer
│   ├── authService.js
│   ├── studentService.js
│   ├── groupService.js
│   ├── positionService.js
│   ├── disciplineService.js
│   └── announcementService.js
│
├── database/          # SQL migration files
│   ├── MASTER_DATABASE_SETUP.sql
│   ├── FIX_ADD_DATE_OF_BIRTH.sql
│   ├── ADD_NOTIFICATION_READ_STATUS.sql
│   └── ...
│
├── supabase/         # Supabase config
│   ├── migrations/   # Database migrations
│   ├── functions/    # Edge functions
│   └── schema.sql    # Database schema
│
├── docs/             # Documentation
│   ├── README.md
│   ├── AVATAR_FEATURE_GUIDE.md
│   ├── CLEAN_URL_GUIDE.md
│   └── ...
│
├── login.html        # Trang đăng nhập
├── index.html        # Landing page
├── unauthorized.html # 403 page
├── vercel.json       # Vercel deployment config
├── _redirects        # Netlify redirects
└── .htaccess         # Apache clean URLs

```

## 🚀 Tech Stack

- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Deployment**: Vercel / Netlify / Apache
- **Design**: Custom design system với glassmorphism

## ⚙️ Setup

1. **Clone repository**
   ```bash
   git clone <repo-url>
   cd tech-student
   ```

2. **Setup Supabase**
   - Tạo project mới tại [supabase.com](https://supabase.com)
   - Chạy các file SQL trong folder `database/` theo thứ tự:
     1. `MASTER_DATABASE_SETUP.sql`
     2. `FIX_ADD_DATE_OF_BIRTH.sql`
     3. `ADD_NOTIFICATION_READ_STATUS.sql`
     4. `SETUP_AVATAR_STORAGE.sql`

3. **Configure Supabase client**
   - Copy Supabase URL và anon key
   - Update trong `assets/js/supabaseClient.js`:
   ```javascript
   const SUPABASE_URL = 'your-project-url'
   const SUPABASE_ANON_KEY = 'your-anon-key'
   ```

4. **Deploy**
   - Vercel: `vercel deploy`
   - Netlify: Drag & drop folder
   - Apache: Upload + enable mod_rewrite

## 📖 Features

### Admin
- ✅ Dashboard với thống kê tổng quan
- ✅ Quản lý danh sách học sinh (CRUD)
- ✅ Quản lý tổ học tập (4 tổ)
- ✅ Phân công chức vụ lớp
- ✅ Ghi nhận vi phạm + trừ điểm nề nếp
- ✅ Đăng thông báo lớp học
- ✅ Quản lý tài khoản user

### Student
- ✅ Trang chủ với thống kê cá nhân
- ✅ Xem danh sách bạn bè (avatar theo giới tính)
- ✅ Xem thành viên tổ + chức vụ
- ✅ Tra cứu điểm nề nếp cá nhân
- ✅ Đọc thông báo (notification badge)
- ✅ Cập nhật hồ sơ + avatar

## 🎨 Design System

- **Colors**:
  - Primary: `#4f6df5` (Blue)
  - Success: `#22c9a8` (Mint)
  - Warning: `#f5a524` (Amber)
  - Danger: `#ef4444` (Red)

- **Typography**: 
  - Headings: Sora (700-800)
  - Body: Inter (400-600)

- **Sidebar**: 
  - Fixed 56px width
  - Icon only with tooltip on hover
  - Active state = gradient fill

## 📝 Database Schema

Xem chi tiết trong `database/MASTER_DATABASE_SETUP.sql`

Các bảng chính:
- `profiles` - Thông tin user
- `students` - Học sinh lớp 12A2
- `groups` - 4 tổ học tập
- `positions` - Chức vụ lớp
- `student_positions` - Phân công chức vụ
- `discipline_logs` - Lịch sử vi phạm
- `announcements` - Thông báo
- `announcement_reads` - Trạng thái đã đọc

## 🔐 Security

- Row Level Security (RLS) enabled trên tất cả tables
- Students chỉ xem được data của chính mình
- Admins có full access
- Auth dùng Supabase Auth

## 📱 Responsive

- Desktop: Full layout với sidebar
- Mobile: Collapsible sidebar với hamburger menu
- Tablet: Adaptive grid layout

## 🐛 Troubleshooting

Xem các file trong `docs/` folder:
- `FIX_RLS_README.md` - Fix RLS recursion errors
- `AVATAR_FEATURE_GUIDE.md` - Setup avatar upload
- `CLEAN_URL_GUIDE.md` - Setup clean URLs

## 📄 License

MIT License - Free to use for educational purposes

---

Made with ❤️ for Lớp 12A2
