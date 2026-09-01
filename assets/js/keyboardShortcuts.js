/* ============================================================
   KEYBOARD SHORTCUTS
   Modern keyboard navigation for power users
   ============================================================ */

export class KeyboardShortcuts {
  constructor() {
    this.shortcuts = new Map();
    this.enabled = true;
    this.init();
  }

  init() {
    document.addEventListener('keydown', (e) => {
      if (!this.enabled) return;
      
      // Ignore if user is typing in input/textarea
      const activeElement = document.activeElement;
      if (activeElement.tagName === 'INPUT' || 
          activeElement.tagName === 'TEXTAREA' || 
          activeElement.contentEditable === 'true') {
        return;
      }

      const key = this.getKeyCombo(e);
      const handler = this.shortcuts.get(key);
      
      if (handler) {
        e.preventDefault();
        handler(e);
      }
    });
  }

  getKeyCombo(e) {
    const parts = [];
    if (e.ctrlKey || e.metaKey) parts.push('ctrl');
    if (e.altKey) parts.push('alt');
    if (e.shiftKey) parts.push('shift');
    parts.push(e.key.toLowerCase());
    return parts.join('+');
  }

  register(keys, handler, description = '') {
    if (Array.isArray(keys)) {
      keys.forEach(key => this.shortcuts.set(key, handler));
    } else {
      this.shortcuts.set(keys, handler);
    }
  }

  unregister(keys) {
    if (Array.isArray(keys)) {
      keys.forEach(key => this.shortcuts.delete(key));
    } else {
      this.shortcuts.delete(keys);
    }
  }

  enable() {
    this.enabled = true;
  }

  disable() {
    this.enabled = false;
  }

  getAll() {
    return Array.from(this.shortcuts.entries());
  }
}

// Global shortcuts instance
export const shortcuts = new KeyboardShortcuts();

// Common shortcuts
export function registerCommonShortcuts() {
  // Quick search: Ctrl+K or Cmd+K
  shortcuts.register(['ctrl+k', 'meta+k'], () => {
    const searchInput = document.querySelector('.search-input');
    if (searchInput) {
      searchInput.focus();
      searchInput.select();
    }
  });

  // Close modals/overlays: Escape
  shortcuts.register('escape', () => {
    // Close notification center
    const notificationCenter = document.querySelector('.notification-center');
    if (notificationCenter?.classList.contains('open')) {
      notificationCenter.classList.remove('open');
      document.querySelector('.notification-overlay')?.classList.remove('show');
      return;
    }

    // Close modals
    const openModal = document.querySelector('.modal.show, .overlay.show');
    if (openModal) {
      openModal.classList.remove('show');
      return;
    }

    // Close FAB menu
    const fabMenu = document.querySelector('.fab-menu.show');
    if (fabMenu) {
      fabMenu.classList.remove('show');
    }
  });

  // Show keyboard shortcuts help: ?
  shortcuts.register('?', () => {
    showShortcutsHelp();
  });
}

// Show shortcuts help modal
function showShortcutsHelp() {
  const helpModal = document.createElement('div');
  helpModal.className = 'overlay show';
  helpModal.innerHTML = `
    <div class="modal" style="max-width:600px;">
      <div class="modal-head">
        <h3>⌨️ Keyboard Shortcuts</h3>
        <button class="close-x" onclick="this.closest('.overlay').remove()">✕</button>
      </div>
      <div class="modal-body">
        <div style="display:grid;gap:12px;">
          <div class="shortcut-item">
            <div class="shortcut-keys"><kbd>Ctrl</kbd> + <kbd>K</kbd></div>
            <div class="shortcut-desc">Quick search</div>
          </div>
          <div class="shortcut-item">
            <div class="shortcut-keys"><kbd>Esc</kbd></div>
            <div class="shortcut-desc">Close modals/panels</div>
          </div>
          <div class="shortcut-item">
            <div class="shortcut-keys"><kbd>?</kbd></div>
            <div class="shortcut-desc">Show this help</div>
          </div>
          <div class="shortcut-item">
            <div class="shortcut-keys"><kbd>Ctrl</kbd> + <kbd>N</kbd></div>
            <div class="shortcut-desc">New item (context-aware)</div>
          </div>
          <div class="shortcut-item">
            <div class="shortcut-keys"><kbd>Ctrl</kbd> + <kbd>S</kbd></div>
            <div class="shortcut-desc">Save (if applicable)</div>
          </div>
        </div>
      </div>
      <div class="modal-foot">
        <button class="btn" onclick="this.closest('.overlay').remove()">Got it</button>
      </div>
    </div>
  `;
  document.body.appendChild(helpModal);
}

// Styles for shortcuts help
const style = document.createElement('style');
style.textContent = `
.shortcut-item{
  display:flex;
  align-items:center;
  justify-content:space-between;
  padding:12px;
  background:var(--bg);
  border-radius:var(--radius-sm);
}

.shortcut-keys{
  display:flex;
  gap:6px;
  align-items:center;
  font-size:13px;
  color:var(--ink-600);
}

.shortcut-keys kbd{
  padding:4px 8px;
  background:var(--card);
  border:1px solid var(--line);
  border-radius:6px;
  font-family:monospace;
  font-size:12px;
  box-shadow:0 2px 4px rgba(0,0,0,0.05);
}

.shortcut-desc{
  font-size:14px;
  color:var(--ink-900);
  font-weight:500;
}
`;
document.head.appendChild(style);
