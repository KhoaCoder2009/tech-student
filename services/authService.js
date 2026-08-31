/* services/authService.js — logic xác thực bằng email ảo đã cấp qua Supabase Auth.
   Fallback demo/test: tài khoản dạng @techstudent.local có thể đăng nhập trực tiếp không cần mật khẩu/link. */
import { supabase, ROLE_LABEL } from '../assets/js/supabaseClient.js';

const DEMO_SESSION_KEY = 'techstudent-demo-session';

export function toEmail(identifier){
  const v = String(identifier || '').trim();
  return v.includes('@') ? v.toLowerCase() : `${v.toLowerCase()}@techstudent.local`;
}

export function isDemoAccount(identifier){
  const email = toEmail(identifier).toLowerCase();
  return email.endsWith('@techstudent.local');
}

function resolveDemoUser(email){
  const base = String(email || '').toLowerCase();
  const local = base.replace(/@.*$/, '');

  const seed = {
    admin: { full_name: 'Quản trị viên', role: 'admin' },
    teacher: { full_name: 'Giáo viên', role: 'teacher' },
    student: { full_name: 'Học sinh', role: 'student' }
  };

  if (base === 'admin@techstudent.local') return { id: 'demo-admin', full_name: seed.admin.full_name, role: seed.admin.role, roleLabel: ROLE_LABEL[seed.admin.role] || seed.admin.role, email: base };
  if (['teacher', 'gv', 'giao-vien'].includes(local)) return { id: 'demo-teacher', full_name: seed.teacher.full_name, role: seed.teacher.role, roleLabel: ROLE_LABEL[seed.teacher.role] || seed.teacher.role, email: base };
  if (local === 'stt') return { id: 'demo-stt', full_name: 'Sinh viên STT', role: 'student', roleLabel: ROLE_LABEL.student, email: base + '@techstudent.local' };

  const numberOnly = /^\d+$/.test(local);
  if (numberOnly) return { id: `demo-student-${local}`, full_name: `Học sinh ${local}`, role: 'student', roleLabel: ROLE_LABEL.student, email: base };

  return { id: `demo-user-${local || 'anon'}`, full_name: local || 'Người dùng', role: 'student', roleLabel: ROLE_LABEL.student, email: base };
}

/** Đăng nhập trực tiếp cho tài khoản ảo không cần mật khẩu / link. */
export async function signIn(identifier){
  const email = toEmail(identifier);

  if (isDemoAccount(email)) {
    const demoUser = resolveDemoUser(email);
    localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(demoUser));
    return { email, demo: true, user: demoUser };
  }

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: `${window.location.origin}/admin/dashboard.html` }
  });

  if(error) throw new Error(error.message || 'Không thể gửi liên kết đăng nhập bằng email.');

  return { email, demo: false };
}

/** Trả về user hiện tại (demo session local hoặc session Supabase thật). */
export async function getCurrentUser(){
  const demoRaw = localStorage.getItem(DEMO_SESSION_KEY);
  if (demoRaw) {
    try {
      const demoUser = JSON.parse(demoRaw);
      if (demoUser?.email) return demoUser;
    } catch (error) {
      console.warn('Invalid demo session', error);
      localStorage.removeItem(DEMO_SESSION_KEY);
    }
  }

  const { data:{ session } } = await supabase.auth.getSession();
  if(!session) return null;
  const { data: profile, error } = await supabase
    .from('profiles').select('role, full_name, is_active').eq('id', session.user.id).single();
  if(error || !profile || !profile.is_active) return null;
  return { id: session.user.id, full_name: profile.full_name, role: profile.role, roleLabel: ROLE_LABEL[profile.role] || profile.role };
}

export async function signOut(){
  localStorage.removeItem(DEMO_SESSION_KEY);
  if (supabase?.auth?.signOut) await supabase.auth.signOut();
}

export async function sendPasswordReset(identifier){
  const email = toEmail(identifier);
  await supabase.auth.resetPasswordForEmail(email, { redirectTo: window.location.origin + '/reset-password.html' });
}

/** Cấp tài khoản mới (Admin only). Tạo Auth user cần quyền service_role,
    KHÔNG an toàn nếu gọi trực tiếp từ frontend bằng anon key — nên phải đi qua
    Supabase Edge Function chạy phía server (xem supabase/functions/create-account). */
export async function createAccount({ email, full_name, role }){
  const { data, error } = await supabase.functions.invoke('create-account', {
    body: { email, full_name, role }
  });
  if(error) throw new Error(error.message || 'Không thể tạo tài khoản.');
  return data;
}
