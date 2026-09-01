/* ============================================================
   STUDENT LAYOUT — Layout cho học sinh
   ============================================================ */
import { supabase } from './supabaseClient.js';
import { getCurrentUser, signOut } from '../../services/authService.js';
import { confirmModal } from './ui.js';

export const STUDENT_NAV_ITEMS = [
  { page: 'home', href: '/student/home.html', icon: '🏠', label: 'Tổng quan' },
  { page: 'friends', href: '/student/friends.html', icon: '👥', label: 'Bạn bè' },
  { page: 'mygroup', href: '/student/mygroup.html', icon: '🗂️', label: 'Tổ' },
  { page: 'discipline', href: '/student/discipline.html', icon: '⭐', label: 'Nề nếp' },
  { page: 'announcements', href: '/student/announcements.html', icon: '📢', label: 'Thông báo' },
];

function sidebarHtml(activePage, navItems = STUDENT_NAV_ITEMS) {
  return `
    <div class="sidebar-scrim" id="scrim"></div>
    <aside class="sidebar" id="sidebar">
      <div class="brand">
        <div class="brand-mark">
          <img src="../assets/images/logo.png" alt="12A2" onerror="this.parentElement.innerHTML='<span style=&quot;font-size:20px;font-weight:800;color:#d94750;&quot;>12A2</span>'">
        </div>
      </div>
      <nav class="nav-group">
        ${navItems.map(item => navLink(item, activePage)).join('')}
      </nav>
    </aside>
  `;
}

function navLink(item, activePage) {
  const isActive = item.page === activePage;
  return `
    <a href="${item.href}" class="nav-item${isActive ? ' active' : ''}" data-tooltip="${item.label}">
      <span class="ic">${item.icon}</span>
      <span class="label">${item.label}</span>
    </a>
  `;
}

function topbarHtml(title, subtitle) {
  return `
    <header class="topbar">
      <button class="hamburger" id="menu-toggle" aria-label="Mở menu">☰</button>
      <div class="topbar-left">
        <h1>${title}</h1>
        ${subtitle ? `<div class="sub">${subtitle}</div>` : ''}
      </div>
      <div class="topbar-right">
        <div class="quick-action-group">
          <button class="icon-btn" id="btn-notif" title="Thông báo" aria-label="Thông báo">
            <span>🔔</span>
            <span class="dot-badge" style="display:none;"></span>
          </button>
          <button class="icon-btn" id="btn-profile" title="Hồ sơ cá nhân" aria-label="Hồ sơ cá nhân">
            <span>👤</span>
          </button>
          <button class="icon-btn" id="btn-theme-toggle" title="Chế độ tối" aria-label="Chế độ tối">
            <span>🌙</span>
          </button>
          <button class="icon-btn" id="btn-settings" title="Cài đặt" aria-label="Cài đặt">
            <span>⚙️</span>
          </button>
        </div>
        <div class="side-user" id="user-summary" style="cursor:pointer;">
          <div class="avatar">👤</div>
          <div>
            <div class="name" id="user-name">Học sinh</div>
            <div class="role">Học sinh</div>
          </div>
        </div>
      </div>
      <div class="dropdown-menu" id="settings-menu" style="display:none;position:absolute;top:100%;right:20px;background:var(--card);border:1px solid var(--line);border-radius:var(--radius-md);box-shadow:var(--shadow-md);padding:8px;min-width:200px;z-index:50;">
        <a href="/student/profile.html" class="dropdown-item" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">👤 Hồ sơ cá nhân</a>
        <a href="/student/change-password.html" class="dropdown-item" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">🔒 Đổi mật khẩu</a>
        <a href="#" class="dropdown-item" id="toggle-dark-mode" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">🌙 Chế độ tối</a>
        <a href="#" class="dropdown-item" id="btn-logout" style="display:block;padding:8px 12px;color:var(--ink-900);text-decoration:none;border-radius:6px;transition:all 0.2s;">🚪 Đăng xuất</a>
      </div>
    </header>
  `;
}

export async function initStudentLayout(opts = {}) {
  const { page = 'dashboard', title = 'Dashboard', sub = '' } = opts;

  const user = await getCurrentUser();
  if (!user) {
    window.location.href = '../login.html';
    return null;
  }

  // Role guard: only students can access student pages
  if (user.role !== 'student') {
    window.location.href = '../unauthorized.html';
    return null;
  }

  document.getElementById('sidebar-slot').innerHTML = sidebarHtml(page);
  document.getElementById('topbar-slot').innerHTML = topbarHtml(title, sub);

  const userName = document.getElementById('user-name');
  if (userName && user.full_name) {
    userName.textContent = user.full_name;
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
  const btnProfile = document.getElementById('btn-profile');
  const btnThemeToggle = document.getElementById('btn-theme-toggle');
  const settingsMenu = document.getElementById('settings-menu');
  const userSummary = document.getElementById('user-summary');
  const btnDarkMode = document.getElementById('toggle-dark-mode');
  const updateThemeButton = () => {
    const isDark = document.body.classList.contains('dark-mode');
    if (btnThemeToggle) btnThemeToggle.innerHTML = isDark ? '<span>☀️</span>' : '<span>🌙</span>';
    if (btnDarkMode) btnDarkMode.textContent = isDark ? '☀️ Chế độ sáng' : '🌙 Chế độ tối';
  };
  const toggleDarkMode = () => {
    const isDark = !document.body.classList.contains('dark-mode');
    document.body.classList.toggle('dark-mode', isDark);
    localStorage.setItem('darkMode', String(isDark));
    updateThemeButton();
  };
  
  const toggleSettings = (e) => {
    e?.stopPropagation();
    if (!settingsMenu) return;
    const isVisible = settingsMenu.style.display === 'block';
    settingsMenu.style.display = isVisible ? 'none' : 'block';
  };
  
  btnSettings?.addEventListener('click', toggleSettings);
  btnProfile?.addEventListener('click', () => { window.location.href = '/student/profile.html'; });
  userSummary?.addEventListener('click', () => { window.location.href = '/student/profile.html'; });
  btnThemeToggle?.addEventListener('click', (e) => {
    e.stopPropagation();
    toggleDarkMode();
  });
  
  document.addEventListener('click', () => {
    if (settingsMenu) settingsMenu.style.display = 'none';
  });

  // Hover effects for dropdown items
  const dropdownItems = document.querySelectorAll('.dropdown-item');
  dropdownItems.forEach(item => {
    item.addEventListener('mouseenter', () => {
      item.style.background = 'var(--bg)';
    });
    item.addEventListener('mouseleave', () => {
      item.style.background = 'transparent';
    });
  });

  // Dark mode toggle
  btnDarkMode?.addEventListener('click', (e) => {
    e.preventDefault();
    toggleDarkMode();
  });
  if (localStorage.getItem('darkMode') === 'true') {
    document.body.classList.add('dark-mode');
  }
  updateThemeButton();

  // Notification button
  const btnNotif = document.getElementById('btn-notif');
  btnNotif?.addEventListener('click', () => {
    window.location.href = '/student/announcements.html';
  });

  // Load unread count
  loadUnreadCount();

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

async function loadUnreadCount() {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    // Get student's class
    const { data: student } = await supabase
      .from('students')
      .select('class_id')
      .eq('id', user.id)
      .single();

    if (!student?.class_id) return;

    // Count unread announcements
    const { data: announcements } = await supabase
      .from('announcements')
      .select('id')
      .eq('class_id', student.class_id);

    if (!announcements) return;

    const announcementIds = announcements.map(a => a.id);

    // Get read status
    const { data: reads } = await supabase
      .from('announcement_reads')
      .select('announcement_id')
      .eq('user_id', user.id)
      .in('announcement_id', announcementIds);

    const readIds = new Set(reads?.map(r => r.announcement_id) || []);
    const unreadCount = announcements.filter(a => !readIds.has(a.id)).length;

    // Update badge
    const badge = document.querySelector('.dot-badge');
    if (badge) {
      if (unreadCount > 0) {
        badge.style.display = 'block';
        badge.style.background = '#ef4444';
      } else {
        badge.style.display = 'none';
      }
    }
  } catch (error) {
    console.error('Load unread count error:', error);
  }
}
