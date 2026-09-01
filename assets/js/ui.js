/* ============================================================
   UI HELPERS — dùng chung cho mọi trang.
   Thay thế alert()/confirm() bằng toast + confirm modal thật,
   theo đúng style (.toast, .overlay, .modal) trong design system.
   ============================================================ */

function ensureToastWrap(){
  let wrap = document.getElementById('toast-wrap');
  if(!wrap){
    wrap = document.createElement('div');
    wrap.className = 'toast-wrap';
    wrap.id = 'toast-wrap';
    document.body.appendChild(wrap);
  }
  return wrap;
}

export function toast(msg, type=''){
  const wrap = ensureToastWrap();
  const el = document.createElement('div');
  
  // Icon based on type
  const icons = {
    success: '✅',
    err: '❌',
    error: '❌',
    warn: '⚠️',
    warning: '⚠️',
    info: 'ℹ️'
  };
  const icon = icons[type] || '✅';
  
  el.className = 'toast' + (type ? ' toast-' + type : ' toast-success');
  el.innerHTML = `<span class="toast-icon">${icon}</span><span class="toast-message">${msg}</span>`;
  
  wrap.appendChild(el);
  
  // Auto-dismiss with progress bar
  el.style.setProperty('--toast-duration', '3.2s');
  
  setTimeout(() => {
    el.classList.add('toast-exit');
    setTimeout(() => el.remove(), 300);
  }, 3200);
}

function ensureConfirmModal(){
  let overlay = document.getElementById('global-confirm-overlay');
  if(overlay) return overlay;

  overlay = document.createElement('div');
  overlay.className = 'overlay';
  overlay.id = 'global-confirm-overlay';
  overlay.innerHTML = `
    <div class="modal" style="max-width:380px;">
      <div class="modal-body" style="text-align:center;padding-top:26px;">
        <div id="gc-icon" style="font-size:34px;">❓</div>
        <h3 id="gc-title" style="margin:12px 0 6px;">Bạn có chắc chắn?</h3>
        <div id="gc-desc" style="font-size:13px;color:var(--ink-600);"></div>
      </div>
      <div class="modal-foot" style="justify-content:center;">
        <button class="btn btn-ghost" id="gc-cancel">Huỷ</button>
        <button class="btn" id="gc-confirm" style="background:var(--coral-500);color:#fff;">Xác nhận</button>
      </div>
    </div>`;
  document.body.appendChild(overlay);
  return overlay;
}

/**
 * confirmModal({ title, desc, confirmText, danger })
 * Trả về Promise<boolean> — dùng: if(await confirmModal({...})) { ... }
 */
export function confirmModal({ title = 'Bạn có chắc chắn?', desc = '', confirmText = 'Xác nhận', icon = '❓', danger = true } = {}){
  const overlay = ensureConfirmModal();
  overlay.querySelector('#gc-title').textContent = title;
  overlay.querySelector('#gc-desc').textContent = desc;
  overlay.querySelector('#gc-icon').textContent = icon;
  const confirmBtn = overlay.querySelector('#gc-confirm');
  confirmBtn.textContent = confirmText;
  confirmBtn.style.background = danger ? 'var(--coral-500)' : 'var(--navy-950)';
  overlay.classList.add('show');

  return new Promise(resolve => {
    const cancelBtn = overlay.querySelector('#gc-cancel');
    const cleanup = (result) => {
      overlay.classList.remove('show');
      confirmBtn.removeEventListener('click', onConfirm);
      cancelBtn.removeEventListener('click', onCancel);
      resolve(result);
    };
    const onConfirm = () => cleanup(true);
    const onCancel = () => cleanup(false);
    confirmBtn.addEventListener('click', onConfirm);
    cancelBtn.addEventListener('click', onCancel);
  });
}

/** Render hàng skeleton loading thật vào <tbody> trong lúc chờ Supabase trả dữ liệu. */
export function skeletonRows(tbody, cols, rows = 5){
  tbody.innerHTML = Array.from({ length: rows }).map(() => `
    <tr class="skel-row">${Array.from({ length: cols }).map(() => `<td><div class="skeleton skel-bar"></div></td>`).join('')}</tr>
  `).join('');
}

/** Render banner lỗi thật (không phải alert) với nút thử lại. */
export function errorBanner(container, message, onRetry){
  const el = document.createElement('div');
  el.className = 'error-banner';
  el.innerHTML = `<span>⚠️ ${message}</span><button>Thử lại</button>`;
  el.querySelector('button').addEventListener('click', () => { el.remove(); onRetry && onRetry(); });
  container.prepend(el);
}
