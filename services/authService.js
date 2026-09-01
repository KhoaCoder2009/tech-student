/* services/authService.js — xác thực dựa trên profile trong Supabase, không gửi email xác nhận. */
import { supabase, ROLE_LABEL } from '../assets/js/supabaseClient.js';

const LOCAL_SESSION_KEY = 'techstudent-supabase-session';

export function toEmail(identifier){
  const v = String(identifier || '').trim();
  return v.includes('@') ? v.toLowerCase() : `${v.toLowerCase()}@techstudent.local`;
}

export async function resolveProfileByIdentifier(identifier){
  const raw = String(identifier || '').trim();
  if(!raw) throw new Error('Vui lòng nhập tài khoản.');

  const email = toEmail(raw);
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('id, role, full_name, email, is_active')
    .eq('email', email)
    .maybeSingle();

  if(error) throw new Error(error.message || 'Không thể kiểm tra tài khoản trong Supabase.');
  if(!profile) throw new Error(`Không tìm thấy tài khoản "${raw}" trong Supabase.`);
  if(!profile.is_active) throw new Error('Tài khoản này đang bị khoá.');

  return {
    id: profile.id,
    full_name: profile.full_name,
    role: profile.role,
    email: profile.email || email,
    roleLabel: ROLE_LABEL[profile.role] || profile.role
  };
}

/** Đăng nhập bằng tài khoản và mật khẩu thực của Supabase Auth, sau đó kiểm tra profile tương ứng. */
export async function signIn(identifier, password){
  const raw = String(identifier || '').trim();
  if(!raw) throw new Error('Vui lòng nhập tài khoản.');
  if(!password) throw new Error('Vui lòng nhập mật khẩu.');

  const email = toEmail(raw);

  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (authError) {
    throw new Error(authError.message || 'Sai tài khoản hoặc mật khẩu.');
  }

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, role, full_name, email, is_active')
    .eq('id', authData.user.id)
    .maybeSingle();

  if (profileError) throw new Error(profileError.message || 'Không thể xác thực hồ sơ người dùng.');
  if (!profile) {
    throw new Error(`Tài khoản ${email} chưa có hồ sơ trong bảng profiles.`);
  }
  if (!profile.is_active) throw new Error('Tài khoản này đang bị khoá.');

  const normalizedProfile = {
    id: profile.id,
    full_name: profile.full_name,
    role: profile.role,
    email: profile.email || email,
    roleLabel: ROLE_LABEL[profile.role] || profile.role,
  };

  localStorage.setItem(LOCAL_SESSION_KEY, JSON.stringify(normalizedProfile));
  return { email: normalizedProfile.email, user: normalizedProfile, demo: false };
}

/** Trả về user hiện tại từ session local đã được lưu theo profile Supabase. */
export async function getCurrentUser(){
  const raw = localStorage.getItem(LOCAL_SESSION_KEY);
  if (!raw) return null;

  try {
    const profile = JSON.parse(raw);
    if (profile?.id && profile?.role) return profile;
  } catch (error) {
    console.warn('Invalid saved session', error);
    localStorage.removeItem(LOCAL_SESSION_KEY);
  }

  return null;
}

export async function signOut(){
  localStorage.removeItem(LOCAL_SESSION_KEY);
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
