# 🎨 LOGO SETUP GUIDE

## ✅ ĐÃ TÍCH HỢP LOGO

Logo rồng xanh đã được tích hợp vào sidebar!

---

## 📂 CÀI ĐẶT

### Bước 1: Lưu logo

1. **Tải ảnh logo** (rồng xanh) về máy
2. **Đổi tên** thành: `logo.png`
3. **Copy** vào folder: `assets/images/logo.png`

### Bước 2: Test

1. **Reload** trang student dashboard
2. Logo sẽ hiển thị ở **góc trên sidebar**
3. Hover vào logo → có hiệu ứng scale + rotate

---

## 🎨 STYLE

**Logo container:**
- ✅ Kích thước: 40x40px
- ✅ Border radius: 12px
- ✅ Background: trắng
- ✅ Shadow: xanh dương
- ✅ Hover: scale 1.1 + rotate 5deg

**Fallback:**
- Nếu ảnh không load được → hiện chữ "TS"

---

## 📍 VỊ TRÍ FILE

```
tech-student/
├── assets/
│   ├── images/
│   │   └── logo.png  ← Đặt logo ở đây
│   ├── css/
│   │   └── design-system.css  ← Đã update style
│   └── js/
│       └── studentLayout.js  ← Đã update HTML
```

---

## 🔧 TUỲ CHỈNH

### Đổi kích thước logo:

File: `assets/css/design-system.css`

```css
.brand-mark{
  width:50px;   /* Tăng từ 40px */
  height:50px;  /* Tăng từ 40px */
}
```

### Đổi background:

```css
.brand-mark{
  background:#fff;  /* Trắng */
  /* hoặc */
  background:linear-gradient(135deg, #4f6df5, #22c9a8);  /* Gradient */
}
```

### Đổi border-radius:

```css
.brand-mark{
  border-radius:12px;  /* Bo góc vừa */
  /* hoặc */
  border-radius:50%;   /* Hình tròn */
}
```

---

## ✨ HIỆU ỨNG

**Đã có:**
- ✅ Hover scale + rotate
- ✅ Shadow animation
- ✅ Smooth transition

**Có thể thêm:**
```css
.brand-mark:hover{
  animation:pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { transform:scale(1); }
  50% { transform:scale(1.1); }
}
```

---

## 🎯 KẾT QUẢ

**Sidebar trước:**
```
┌────┐
│ TS │  ← Text "TS"
└────┘
```

**Sidebar sau:**
```
┌────────┐
│  🐉   │  ← Logo rồng xanh
└────────┘
```

---

## 📝 GHI CHÚ

- Logo tự động fallback về "TS" nếu file không tồn tại
- Background trắng để logo rồng xanh nổi bật
- Object-fit: contain để giữ tỷ lệ logo
- Padding 2px để logo không sát mép

---

**Chỉ cần bỏ file `logo.png` vào `assets/images/` là xong!** 🎨
