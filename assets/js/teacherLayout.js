/* ============================================================
   TEACHER LAYOUT — Layout cho giáo viên chủ nhiệm (GVCN)
   ============================================================ */
import { getCurrentUser, signOut } from '../../services/authService.js';
import { confirmModal } from './ui.js';

export const GVCN_NAV_ITEMS = [
  { group: null, page: 'dashboard', href: 'dashboard.html', icon: '🏠', label: 'Tổng quan' },
  { group: 'Lớp chủ nhiệm', page: 'students', href: '../admin/students.html', icon: '👥', label: 'Học sinh' },
  { group: 'Lớp chủ nhiệm', page: 'groups', href: '../admin/groups.html', icon: '🗂️', label: 'Tổ' },
  { group: 'Lớp chủ nhiệm', page: 'seating', href: '../admin/seating.html', icon: '🪑', label: 'Sơ đồ lớp' },
  { group: 'Nề nếp', page: 'set-discipline-score', href: '../admin/set-discipline-score.html', icon: '⭐', label: 'Điểm nề nếp' },
  { group: 'Nề nếp', page: 'discipline', href: '../admin/discipline.html', icon: '📝', label: 'Lịch sử' },
  { group: 'Giao tiếp', page: 'announcements', href: '../admin/announcements.html', icon: '📢', label: 'Thông báo' },
];

function sidebarHtml(activePage, navItems = GVCN_NAV_ITEMS) {
  let html = `
    <div class="sidebar-scrim" id="scrim"></div>
    <aside class="sidebar" id="sidebar">
      <div class="brand">
        <div class="brand-mark" style="background:linear-gradient(135deg,#4f6df5,#22c9a8);">
          <span style="font-size:20px;font-weight:800;color:#fff;">TS</span>
        </div>
      </div>
      <nav class="nav-group">
        ${navLink(navItems[0], activePage)}
      </nav>
  `;

  const grouped = {};
  navItems.slice(1).forEach(item => {
    if (!item.group) return;
    if (!grouped[item.group]) grouped[item.group] = [];
    grouped[item.group].push(item);
  });

  for (const [groupName, items] of Object.entries(grouped)) {
    html += `
      <nav class="nav-group">
        <div class="nav-label">${groupName}</div>
        ${items.map(item => navLink(item, activePage)).join('')}
      </nav>
    `;
  }

  html += `
    </aside>
  `;
  return html;
}

function navLink(item, activePage) {
  const isActive = item.page === activePage;
  return `
    <a href="${item.href}" class="nav-item${isActive ? ' active' : ''}">
      <span class="ic">${item.icon}</span>
      <span class="label">${item.label}</span>
    </a>
  `;
}

function topbarHtml(title, subtitle) {
  return `
    <header class="topbar">
      <div class="topbar-left">
        <button class="menu-toggle" id="menu-toggle">☰</button>
        <div class="breadcrumb">
          <span class="bc-title">${title}</span>
          ${subtitle ? `<span class="bc-sub">${subtitle}</span>` : ''}
        </div>
      </div>
      <div class="topbar-right">
        <button class="top-btn" id="btn-notif" title="Thông báo">
          <span class="icon">🔔</span>
          <span class="badge">3</span>
        </button>
        <button class="top-btn" id="btn-settings" title="Cài đặt">⚙️</button>
        <button class="top-btn" id="btn-profile">
          <span class="avatar">👤</span>
          <span class="uname" id="user-name">GVCN</span>
        </button>
      </div>
      <div class="dropdown-menu" id="settings-menu">
        <a href="../admin/profile.html" class="dropdown-item">👤 Hồ sơ cá nhân</a>
        <a href="#" class="dropdown-item" id="toggle-dark-mode">🌙 Chế độ tối</a>
        <a href="../admin/change-password.html" class="dropdown-item">🔒 Đổi mật khẩu</a>
        <a href="#" class="dropdown-item" id="btn-logout">🚪 Đăng xuất</a>
      </div>
    </header>
  `;
}

export async function initTeacherLayout(opts = {}) {
  const { page = 'dashboard', title = 'GVCN Dashboard', sub = '' } = opts;

  const user = await getCurrentUser();
  if (!user) {
    window.location.href = '../login.html';
    return null;
  }

  document.getElementById('sidebar-slot').innerHTML = sidebarHtml(page);
  document.getElementById('topbar-slot').innerHTML = topbarHtml(title, sub);

  const userName = document.getElementById('user-name');
  if (userName && user.profile?.full_name) {
    userName.textContent = user.profile.full_name;
  }

  // Menu toggle
  const menuToggle = document.getElementById('menu-toggle');
  const sidebar = document.getElementById('sidebar');
  const scrim = document.getElementById('scrim');
  menuToggle?.addEventListener('click', () => {
    sidebar.classList.toggle('open');
    scrim.classList.toggle('show');
  });
  scrim?.addEventListener('click', () => {
    sidebar.classList.remove('open');
    scrim.classList.remove('show');
  });

  // Settings dropdown
  const btnSettings = document.getElementById('btn-settings');
  const settingsMenu = document.getElementById('settings-menu');
  btnSettings?.addEventListener('click', (e) => {
    e.stopPropagation();
    settingsMenu.classList.toggle('show');
  });
  document.addEventListener('click', () => settingsMenu.classList.remove('show'));

  // Dark mode toggle
  const btnDarkMode = document.getElementById('toggle-dark-mode');
  btnDarkMode?.addEventListener('click', (e) => {
    e.preventDefault();
    document.body.classList.toggle('dark-mode');
    localStorage.setItem('darkMode', document.body.classList.contains('dark-mode'));
  });
  if (localStorage.getItem('darkMode') === 'true') {
    document.body.classList.add('dark-mode');
  }

  // Notification button
  const btnNotif = document.getElementById('btn-notif');
  btnNotif?.addEventListener('click', () => {
    window.location.href = '../admin/announcements.html';
  });

  // Logout
  const btnLogout = document.getElementById('btn-logout');
  btnLogout?.addEventListener('click', async (e) => {
    e.preventDefault();
    const confirmed = await confirmModal('Bạn có chắc muốn đăng xuất?');
    if (confirmed) {
      await signOut();
      window.location.href = '../login.html';
    }
  });

  return user;
}
