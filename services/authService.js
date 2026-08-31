/* services/authService.js — logic xác thực bằng email ảo đã cấp qua Supabase Auth.
   Không dùng mật khẩu cho màn hình login. */
import { supabase, ROLE_LABEL } from '../assets/js/supabaseClient.js';

export function toEmail(identifier){
  const v = String(identifier || '').trim();
  return v.includes('@') ? v.toLowerCase() : `${v.toLowerCase()}@student.techstudent.local`;
}

/** Gửi link đăng nhập bằng email ảo đã cấp. */
export async function signIn(identifier){
  const email = toEmail(identifier);

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${window.location.origin}/admin/dashboard.html`
    }
  });

  if(error) throw new Error(error.message || 'Không thể gửi liên kết đăng nhập bằng email.');

  return { email };
}

/** Trả về user hiện tại (session Supabase thật, dựa trên JWT) hoặc null. */
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
