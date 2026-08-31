/* ============================================================
   LAYOUT SHELL — MỘT nơi duy nhất định nghĩa sidebar + topbar.
   Mọi trang admin/*.html gọi initLayout({...}) thay vì tự chép lại
   HTML sidebar, để không bao giờ có 2 phong cách khác nhau.
   ============================================================ */
import { getCurrentUser, signOut } from '../../services/authService.js';
import { confirmModal } from './ui.js';

const NAV_ITEMS = [
  { group: null, page: 'dashboard',    href: 'dashboard.html',    icon: '🏠', label: 'Tổng quan' },
  { group: 'Lớp học', page: 'students',    href: 'students.html',    icon: '👥', label: 'Học sinh' },
  { group: 'Lớp học', page: 'groups',      href: 'groups.html',      icon: '🗂️', label: 'Tổ' },
  { group: 'Lớp học', page: 'positions',   href: 'positions.html',   icon: '🎖️', label: 'Chức vụ' },
  { group: 'Lớp học', page: 'seating',     href: 'seating.html',     icon: '🪑', label: 'Sơ đồ lớp' },
  { group: 'Quản lý', page: 'set-discipline-score', href: 'set-discipline-score.html', icon: '⭐', label: 'Điểm nề nếp' },
  { group: 'Quản lý', page: 'discipline',  href: 'discipline.html',  icon: '📝', label: 'Lịch sử nề nếp' },
  { group: 'Quản lý', page: 'announcements', href: 'announcements.html', icon: '📢', label: 'Thông báo' },
  { group: 'Quản lý', page: 'accounts',    href: 'accounts.html',    icon: '🔐', label: 'Tài khoản' },
];
const BOTTOM_NAV_PAGES = ['dashboard', 'students', 'groups', 'discipline'];

function sidebarHtml(activePage){
  let html = `
    <div class="sidebar-scrim" id="scrim"></div>
    <aside class="sidebar" id="sidebar">
      <nav class="nav-group">
        ${navLink(NAV_ITEMS[0], activePage)}
      </nav>`;

  let currentGroup = null;
  NAV_ITEMS.slice(1).forEach(item => {
    if(item.group !== currentGroup){
      if(currentGroup !== null) html += `</div>`;
      html += `<div class="nav-group"><div class="nav-label">${item.group}</div>`;
      currentGroup = item.group;
    }
    html += navLink(item, activePage);
  });
  html += `</div>`;

  html += `
      <div class="side-foot">
        <div class="side-user" id="side-user" style="cursor:pointer;" title="Đăng xuất">
          <div class="avatar" id="side-avatar">·</div>
          <div>
            <div class="name" id="side-name">Đang tải...</div>
            <div class="role" id="side-role"></div>
          </div>
        </div>
      </div>
    </aside>`;
  return html;
}
function navLink(item, activePage){
  return `<a class="nav-item ${item.page===activePage?'active':''}" href="${item.href}" data-page="${item.page}"><span class="ic">${item.icon}</span><span>${item.label}</span></a>`;
}

function topbarHtml(title, sub){
  return `
    <div class="topbar">
      <button class="hamburger" id="hamburger">☰</button>
      <div>
        <h1 id="page-title">${title}</h1>
        <div class="sub" id="page-sub">${sub}</div>
      </div>
      <div class="topbar-right">
        <button class="icon-btn" id="btn-notifications" title="Thông báo">
          🔔
          <span class="dot-badge" id="notif-badge" style="display:none;"></span>
        </button>
        <button class="icon-btn" id="btn-settings" title="Cài đặt">⚙️</button>
      </div>
    </div>`;
}

function bottomNavHtml(activePage){
  const labels = { 
    dashboard:['🏠','Tổng quan'], 
    students:['👥','Học sinh'], 
    groups:['🗂️','Tổ'], 
    discipline:['⭐','Nề nếp'] 
  };
  return `<nav class="bottom-nav">` + BOTTOM_NAV_PAGES.map(p => `
    <a class="bn-item ${p===activePage?'active':''}" href="${p}.html">
      <span class="ic">${labels[p][0]}</span>${labels[p][1]}
    </a>`).join('') + `</nav>`;
}

/**
 * initLayout({ page, title, sub, allowedRoles })
 * Gọi ở đầu mỗi trang admin/*.html. Trả về Promise<user> sau khi auth guard
 * đã xác nhận hợp lệ — page-specific script chỉ nên chạy phần render dữ liệu
 * SAU khi promise này resolve.
 */
export async function initLayout({ page, title, sub, allowedRoles = ['admin'] }){
  document.getElementById('sidebar-slot').outerHTML = sidebarHtml(page);
  document.getElementById('topbar-slot').outerHTML = topbarHtml(title, sub);
  document.body.insertAdjacentHTML('beforeend', bottomNavHtml(page));

  const sidebar = document.getElementById('sidebar');
  const scrim = document.getElementById('scrim');
  document.getElementById('hamburger').addEventListener('click', () => { sidebar.classList.add('open'); scrim.classList.add('show'); });
  scrim.addEventListener('click', () => { sidebar.classList.remove('open'); scrim.classList.remove('show'); });

  // Topbar buttons
  document.getElementById('btn-notifications')?.addEventListener('click', () => {
    window.location.href = 'announcements.html';
  });

  document.getElementById('btn-settings')?.addEventListener('click', () => {
    showSettingsMenu();
  });

  // ---- AUTH GUARD ----
  const user = await getCurrentUser();
  if(!user){
    window.location.href = '../login.html';
    return null;
  }
  if(!allowedRoles.includes(user.role)){
    window.location.href = '../unauthorized.html';
    return null;
  }

  document.getElementById('side-name').textContent = user.full_name;
  document.getElementById('side-avatar').textContent = (user.full_name || '?').trim().slice(-1).toUpperCase();
  document.getElementById('side-role').textContent = user.roleLabel;

  const sideUserEl = document.getElementById('side-user');
  
  // Click to show menu (Profile or Logout)
  sideUserEl.addEventListener('click', async (e) => {
    // Simple approach: show confirm dialog with options
    const action = await new Promise(resolve => {
      const menu = document.createElement('div');
      menu.style.cssText = 'position:fixed;inset:0;z-index:1000;background:rgba(0,0,0,0.3);display:flex;align-items:center;justify-content:center;';
      menu.innerHTML = `
        <div style="background:white;border-radius:14px;padding:20px;min-width:240px;box-shadow:0 24px 60px rgba(0,0,0,0.3);">
          <div style="font-weight:700;font-size:15px;margin-bottom:14px;color:var(--ink-900);">${user.full_name}</div>
          <button id="menu-profile" style="width:100%;padding:10px;border:1px solid var(--line);border-radius:8px;background:white;text-align:left;font-size:13.5px;margin-bottom:8px;cursor:pointer;display:flex;align-items:center;gap:8px;">👤 Hồ sơ cá nhân</button>
          <button id="menu-logout" style="width:100%;padding:10px;border:1px solid var(--coral-500);border-radius:8px;background:var(--coral-100);color:var(--coral-500);text-align:left;font-size:13.5px;cursor:pointer;display:flex;align-items:center;gap:8px;">🚪 Đăng xuất</button>
        </div>
      `;
      document.body.appendChild(menu);
      
      menu.querySelector('#menu-profile').onclick = () => { document.body.removeChild(menu); resolve('profile'); };
      menu.querySelector('#menu-logout').onclick = () => { document.body.removeChild(menu); resolve('logout'); };
      menu.onclick = (e) => { if(e.target === menu) { document.body.removeChild(menu); resolve(null); } };
    });

    if (action === 'profile') {
      window.location.href = 'profile.html';
    } else if (action === 'logout') {
      const ok = await confirmModal({ title: 'Đăng xuất khỏi Tech-Student?', desc: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng.', confirmText: 'Đăng xuất', icon: '🚪' });
      if(!ok) return;
      await signOut();
      window.location.href = '../login.html';
    }
  });

  return user;
}

// Settings menu
function showSettingsMenu() {
  const menu = document.createElement('div');
  menu.style.cssText = 'position:fixed;inset:0;z-index:1000;background:rgba(0,0,0,0.3);display:flex;align-items:center;justify-content:center;';
  menu.innerHTML = `
    <div style="background:white;border-radius:14px;padding:20px;min-width:280px;box-shadow:0 24px 60px rgba(0,0,0,0.3);">
      <div style="font-weight:700;font-size:16px;margin-bottom:16px;color:var(--ink-900);">⚙️ Cài đặt</div>
      <button id="menu-profile" style="width:100%;padding:12px;border:1px solid var(--line);border-radius:8px;background:white;text-align:left;font-size:14px;margin-bottom:8px;cursor:pointer;display:flex;align-items:center;gap:10px;">👤 Hồ sơ cá nhân</button>
      <button id="menu-dark-mode" style="width:100%;padding:12px;border:1px solid var(--line);border-radius:8px;background:white;text-align:left;font-size:14px;margin-bottom:8px;cursor:pointer;display:flex;align-items:center;gap:10px;">🌙 Chế độ tối</button>
      <button id="menu-change-password" style="width:100%;padding:12px;border:1px solid var(--line);border-radius:8px;background:white;text-align:left;font-size:14px;margin-bottom:8px;cursor:pointer;display:flex;align-items:center;gap:10px;">🔑 Đổi mật khẩu</button>
      <button id="menu-logout" style="width:100%;padding:12px;border:1px solid var(--coral-500);border-radius:8px;background:var(--coral-100);color:var(--coral-500);text-align:left;font-size:14px;cursor:pointer;display:flex;align-items:center;gap:10px;">🚪 Đăng xuất</button>
    </div>
  `;
  document.body.appendChild(menu);
  
  menu.querySelector('#menu-profile').onclick = () => { document.body.removeChild(menu); window.location.href = 'profile.html'; };
  menu.querySelector('#menu-dark-mode').onclick = () => { document.body.removeChild(menu); toggleDarkMode(); };
  menu.querySelector('#menu-change-password').onclick = () => { document.body.removeChild(menu); window.location.href = 'change-password.html'; };
  menu.querySelector('#menu-logout').onclick = async () => { 
    document.body.removeChild(menu); 
    const ok = await confirmModal({ title: 'Đăng xuất khỏi Tech-Student?', desc: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng.', confirmText: 'Đăng xuất', icon: '🚪' });
    if(!ok) return;
    await signOut();
    window.location.href = '../login.html';
  };
  menu.onclick = (e) => { if(e.target === menu) { document.body.removeChild(menu); } };
}

function applyDarkModeState(isDark) {
  document.body.classList.toggle('dark-mode', isDark);
  localStorage.setItem('darkMode', isDark ? 'enabled' : 'disabled');
}

function toggleDarkMode() {
  const isDark = !document.body.classList.contains('dark-mode');
  applyDarkModeState(isDark);
}

// Load dark mode preference
const savedDarkMode = localStorage.getItem('darkMode');
applyDarkModeState(savedDarkMode === 'enabled');
