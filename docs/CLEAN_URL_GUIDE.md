# 🌐 CLEAN URL SETUP

Giấu đuôi `.html` để URL đẹp hơn:
- ❌ `https://domain.com/student/home.html`
- ✅ `https://domain.com/student/home`

---

## 📂 FILES ĐÃ SETUP

### 1. **Vercel** (`vercel.json`)
```json
{
  "cleanUrls": true,
  "trailingSlash": false
}
```
- `cleanUrls: true` → tự động bỏ `.html`
- Deploy: `vercel --prod`

### 2. **Netlify** (`_redirects`)
```
/student/home /student/home.html 200
```
- Mỗi route cần 1 dòng redirect
- Deploy: push to git (auto deploy)

### 3. **Apache** (`.htaccess`)
```apache
RewriteEngine On
RewriteRule ^([^\.]+)$ $1.html [NC,L]
```
- Upload `.htaccess` vào root folder
- Hosting phải support mod_rewrite

---

## 🚀 CÁCH SỬ DỤNG

### Trước khi deploy:
```
https://localhost:5500/student/home.html
```

### Sau khi deploy:
```
https://your-domain.com/student/home
https://your-domain.com/student/dashboard
https://your-domain.com/login
```

---

## ⚙️ TÙY HOSTING

### **Vercel** (Khuyến nghị - Dễ nhất)
1. Push code lên GitHub
2. Connect GitHub với Vercel
3. Deploy
4. Done! `cleanUrls: true` tự động hoạt động

### **Netlify**
1. Push code lên GitHub
2. Connect với Netlify
3. Deploy
4. File `_redirects` tự động được đọc

### **Cloudflare Pages**
- Tương tự Netlify
- Đọc file `_redirects` tự động

### **GitHub Pages**
- ⚠️ Không support rewrite rules
- Phải dùng workaround với 404.html

### **Apache/cPanel**
- Upload `.htaccess` vào root
- Kiểm tra mod_rewrite enabled

---

## 🔗 CẬP NHẬT LINKS

Sau khi deploy, update links trong code:

**Trước:**
```html
<a href="home.html">Trang chủ</a>
```

**Sau:**
```html
<a href="home">Trang chủ</a>
```

**Hoặc giữ nguyên** - hosting sẽ tự redirect!

---

## ✅ KIỂM TRA

Sau deploy, test:
```
https://your-domain.com/student/home     ✅ Hoạt động
https://your-domain.com/student/home.html ✅ Redirect về /student/home
https://your-domain.com/login             ✅ Hoạt động
```

---

## 🐛 TROUBLESHOOTING

### Lỗi 404
- Kiểm tra file có đúng folder không
- Vercel: Check `vercel.json` syntax
- Netlify: Check `_redirects` format

### Lỗi redirect loop
- Remove trailing slash trong config
- Check trùng rules

### CSS/JS không load
- Path phải relative: `../assets/css/style.css`
- Hoặc absolute: `/assets/css/style.css`

---

**Ready to deploy!** 🚀
