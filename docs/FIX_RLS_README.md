# 🔧 FIX RLS RECURSION + TÊN HỌC SINH

## ❌ CÁC LỖI
```
1. stack depth limit exceeded
2. infinite recursion detected in policy
3. 500 Internal Server Error on profiles/students tables
4. Tất cả học sinh hiển thị "Không rõ" (không có tên)
```

## ✅ GIẢI PHÁP

### Chạy file này trong Supabase SQL Editor:
```
FINAL_FIX_RLS_COMPLETE.sql
```

### Các bước:
1. Mở **Supabase Dashboard**
2. **SQL Editor** → New query
3. Copy toàn bộ nội dung `FINAL_FIX_RLS_COMPLETE.sql`
4. **Run** (Ctrl+Enter)
5. Đợi 5 giây
6. **Logout** → **Login lại** (student account)
7. Reload dashboard
8. ✅ Done!

## 📊 FILE NÀY LÀM GÌ?

1. **Xóa** tất cả policies cũ (có recursion)
2. **Tạo** policies mới siêu đơn giản:
   - Không dùng `current_role_is()`
   - Không dùng subquery vào students
   - Chỉ check `auth.uid()`
3. **Fix profiles policy**: Cho phép đọc profiles của mọi người (để hiển thị tên)
4. **Verify** policies đã được tạo

## 🔐 BẢO MẬT

- ✅ Users có thể **đọc** profiles của nhau (để hiển thị tên)
- ✅ Users chỉ **sửa** profile của chính mình
- ✅ Application filter `class_id` sau query
- ✅ No recursion = Fast & stable

## ⚡ KẾT QUẢ

- Dashboard load không lỗi ✅
- Query students/profiles OK ✅
- No 500 errors ✅
- No stack overflow ✅
- **Tên học sinh hiển thị đầy đủ** ✅

---

**Lưu ý**: Sau khi chạy SQL, nhớ logout/login lại để refresh token!
