/* services/authService.js — TOÀN BỘ logic xác thực đi qua đây.
   Không còn nhánh demo/mock — mọi thao tác gọi thẳng Supabase Auth thật. */
import { supabase, ROLE_LABEL } from '../assets/js/supabaseClient.js';

export function toEmail(identifier){
  const v = identifier.trim();
  return v.includes('@') ? v : `${v.toLowerCase()}@student.techstudent.local`;
}

/** Đăng nhập. Trả về { user: {id, full_name, role, roleLabel} } hoặc throw Error. */
export async function signIn(identifier, password){
  const email = toEmail(identifier);

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if(error) throw new Error(error.message === 'Invalid login credentials' ? 'Sai mật khẩu hoặc tài khoản không tồn tại.' : error.message);

  const { data: profile, error: pErr } = await supabase
    .from('profiles').select('role, full_name, is_active').eq('id', data.user.id).single();
  if(pErr || !profile) throw new Error('Không tìm thấy hồ sơ người dùng trong bảng profiles. Liên hệ quản trị viên để tạo hồ sơ cho tài khoản này.');
  if(!profile.is_active){
    await supabase.auth.signOut();
    throw new Error('Tài khoản đã bị khoá. Vui lòng liên hệ quản trị viên.');
  }
  return { user: { id: data.user.id, full_name: profile.full_name, role: profile.role, roleLabel: ROLE_LABEL[profile.role] || profile.role } };
}

/** Trả về user hiện tại (session Supabase thật, dựa trên JWT — không phải password) hoặc null. */
export async function getCurrentUser(){
  const { data:{ session } } = await supabase.auth.getSession();
  if(!session) return null;
  const { data: profile, error } = await supabase
    .from('profiles').select('role, full_name, is_active').eq('id', session.user.id).single();
  if(error || !profile || !profile.is_active) return null;
  return { id: session.user.id, full_name: profile.full_name, role: profile.role, roleLabel: ROLE_LABEL[profile.role] || profile.role };
}

export async function signOut(){
  await supabase.auth.signOut();
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
