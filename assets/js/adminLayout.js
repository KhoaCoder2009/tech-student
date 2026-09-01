import { supabase } from './supabaseClient.js';
import { getCurrentUser, signOut } from '../../services/authService.js';

export const ADMIN_NAV_ITEMS = [
  { page: 'dashboard', href: '/admin/dashboard.html', icon: '📊', label: 'Dashboard' },
  { page: 'students', href: '/admin/students.html', icon: '👥', label: 'Học sinh' },
  { page: 'groups', href: '/admin/groups.html', icon: '🗂️', label: 'Tổ học tập' },
  { page: 'positions', href: '/admin/positions.html', icon: '⭐', label: 'Chức vụ' },
  { page: 'discipline', href: '/admin/discipline.html', icon: '📋', label: 'Nề nếp' },
  { page: 'announcements', href: '/admin/announcements.html', icon: '📢', label: 'Thông báo' },
  { page: 'accounts', href: '/admin/accounts.html', icon: '🔐', label: 'Tài khoản' },
];

export async function initAdminLayout(options = {}) {
  const { page, title, subtitle } = options;

  // Check auth using centralized service
  const user = await getCurrentUser();
  if (!user) {
    window.location.href = '/login.html';
    return null;
  }

  // Check role
  if (user.role !== 'admin') {
    window.location.href = '/unauthorized.html';
    return null;
  }

  // Render sidebar
  renderSidebar(page, user);

  // Render topbar
  renderTopbar(title, subtitle, user);

  return user;
}

function renderSidebar(activePage, profile) {
  const sidebarSlot = document.getElementById('sidebar-slot');
  if (!sidebarSlot) return;

  const navHTML = ADMIN_NAV_ITEMS.map(item => {
    const isActive = item.page === activePage;
    return `
      <a href="${item.href}" class="nav-item${isActive ? ' active' : ''}" data-tooltip="${item.label}">
        <span class="ic">${item.icon}</span>
        <span class="label">${item.label}</span>
      </a>
    `;
  }).join('');

  sidebarSlot.innerHTML = `
    <div class="sidebar-scrim" id="scrim"></div>
    <aside class="sidebar" id="sidebar">
      <div class="brand">
        <div class="brand-logo">
          <span class="brand-text">TECH STUDENT</span>
        </div>
      </div>
      <nav class="nav-group">
        ${navHTML}
      </nav>
      <div class="side-foot">
        <div class="side-user" id="side-user" title="Hồ sơ cá nhân">
          <div class="avatar">${profile && profile.full_name ? profile.full_name.trim().slice(-1).toUpperCase() : 'A'}</div>
          <div>
            <div class="name">${profile && profile.full_name ? profile.full_name : 'Admin'}</div>
            <div class="role">Quản trị viên</div>
          </div>
        </div>
        <div class="side-actions">
          <button class="side-action-btn" id="side-theme-toggle" title="Đổi giao diện">
            <span id="side-theme-icon">🌙</span>
          </button>
          <button class="side-action-btn" id="side-settings" title="Cài đặt">⚙️</button>
        </div>
      </div>
    </aside>
  `;

  const sidebar = document.getElementById('sidebar');
  const scrim = document.getElementById('scrim');
  const sideUser = document.getElementById('side-user');
  const sideThemeToggle = document.getElementById('side-theme-toggle');
  const sideThemeIcon = document.getElementById('side-theme-icon');
  const sideSettings = document.getElementById('side-settings');

  sideUser?.addEventListener('click', () => {
    window.location.href = '/admin/profile.html';
  });
  
  function updateThemeIcon() {
    const isDark = document.body.classList.contains('dark-mode');
    if (sideThemeIcon) sideThemeIcon.textContent = isDark ? '☀️' : '🌙';
  }
  
  function toggleDarkMode() {
    const isDark = !document.body.classList.contains('dark-mode');
    document.body.classList.toggle('dark-mode', isDark);
    localStorage.setItem('darkMode', isDark ? 'enabled' : 'disabled');
    updateThemeIcon();
  }
  
  sideThemeToggle?.addEventListener('click', (e) => {
    e.stopPropagation();
    toggleDarkMode();
  });
  
  sideSettings?.addEventListener('click', (e) => {
    e.stopPropagation();
    showSettingsMenu();
  });
  
  updateThemeIcon();

  const menuToggle = document.getElementById('menu-toggle');
  menuToggle?.addEventListener('click', () => {
    sidebar?.classList.toggle('open');
    scrim?.classList.toggle('show');
  });

  scrim?.addEventListener('click', () => {
    sidebar?.classList.remove('open');
    scrim?.classList.remove('show');
  });
  
  function showSettingsMenu() {
    const menu = document.createElement('div');
    menu.style.cssText = 'position:fixed;inset:0;z-index:1000;background:rgba(0,0,0,0.3);display:flex;align-items:center;justify-content:center;';
    menu.innerHTML = `
      <div style="background:var(--card);border-radius:14px;padding:20px;min-width:280px;box-shadow:0 24px 60px rgba(0,0,0,0.3);">
        <div style="font-weight:700;font-size:16px;margin-bottom:16px;color:var(--ink-900);">⚙️ Cài đặt</div>
        <button id="menu-profile" style="width:100%;padding:12px;border:1px solid var(--line);border-radius:8px;background:var(--card);text-align:left;font-size:14px;margin-bottom:8px;cursor:pointer;display:flex;align-items:center;gap:10px;color:var(--ink-900);">👤 Hồ sơ cá nhân</button>
        <button id="menu-change-password" style="width:100%;padding:12px;border:1px solid var(--line);border-radius:8px;background:var(--card);text-align:left;font-size:14px;margin-bottom:8px;cursor:pointer;display:flex;align-items:center;gap:10px;color:var(--ink-900);">🔑 Đổi mật khẩu</button>
        <button id="menu-logout" style="width:100%;padding:12px;border:1px solid var(--coral-500);border-radius:8px;background:var(--coral-100);color:var(--coral-500);text-align:left;font-size:14px;cursor:pointer;display:flex;align-items:center;gap:10px;">🚪 Đăng xuất</button>
      </div>
    `;
    document.body.appendChild(menu);
    
    menu.querySelector('#menu-profile').onclick = () => { document.body.removeChild(menu); window.location.href = '/admin/profile.html'; };
    menu.querySelector('#menu-change-password').onclick = () => { document.body.removeChild(menu); window.location.href = '/admin/change-password.html'; };
    menu.querySelector('#menu-logout').onclick = async () => { 
      document.body.removeChild(menu); 
      await signOut();
      window.location.href = '/login.html';
    };
    menu.onclick = (e) => { if(e.target === menu) { document.body.removeChild(menu); } };
  }
}

function renderTopbar(title, subtitle, profile) {
  const topbarSlot = document.getElementById('topbar-slot');
  if (!topbarSlot) return;

  topbarSlot.innerHTML = `
    <header class="topbar">
      <button class="hamburger" id="menu-toggle" style="display:none;">☰</button>
      <div class="topbar-left">
        <h1>${title || 'Admin'}</h1>
        ${subtitle ? `<div class="sub">${subtitle}</div>` : ''}
      </div>
      <div class="topbar-right">
        <button class="icon-btn" id="btn-notifications" title="Thông báo">
          <span>🔔</span>
        </button>
        <div class="side-user" id="btn-profile">
          <div class="avatar">👨‍💼</div>
          <div>
            <div class="name" id="user-name">${profile && profile.full_name ? profile.full_name : 'Admin'}</div>
            <div class="role">Quản trị viên</div>
          </div>
        </div>
      </div>
      <div class="dropdown-menu" id="settings-menu" style="display:none;position:absolute;top:100%;right:20px;background:var(--card);border:1px solid var(--line);border-radius:var(--radius-md);box-shadow:var(--shadow-md);padding:8px;min-width:200px;z-index:50;">
        <a href="/admin/profile.html" class="dropdown-item" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">👤 Hồ sơ cá nhân</a>
        <a href="/admin/change-password.html" class="dropdown-item" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">🔒 Đổi mật khẩu</a>
        <a href="#" class="dropdown-item" id="btn-logout" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">🚪 Đăng xuất</a>
      </div>
    </header>
  `;

  const btnProfile = document.getElementById('btn-profile');
  const settingsMenu = document.getElementById('settings-menu');

  const toggleSettings = (e) => {
    e.stopPropagation();
    const isVisible = settingsMenu.style.display === 'block';
    settingsMenu.style.display = isVisible ? 'none' : 'block';
  };

  btnProfile?.addEventListener('click', toggleSettings);

  document.addEventListener('click', () => {
    settingsMenu.style.display = 'none';
  });

  const dropdownItems = document.querySelectorAll('.dropdown-item');
  dropdownItems.forEach(item => {
    item.addEventListener('mouseenter', () => {
      item.style.background = 'var(--bg)';
    });
    item.addEventListener('mouseleave', () => {
      item.style.background = 'transparent';
    });
  });

  document.getElementById('btn-notifications')?.addEventListener('click', () => {
    window.location.href = '/admin/announcements.html';
  });

  document.getElementById('btn-logout')?.addEventListener('click', async (e) => {
    e.preventDefault();
    await signOut();
    window.location.href = '/login.html';
  });
  
  // Load dark mode preference
  const savedDarkMode = localStorage.getItem('darkMode');
  if (savedDarkMode === 'enabled') {
    document.body.classList.add('dark-mode');
  }
}
