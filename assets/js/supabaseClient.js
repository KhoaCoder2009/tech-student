/* ============================================================
   SUPABASE CLIENT — MỘT NƠI DUY NHẤT CHO TOÀN HỆ THỐNG.
   Mọi trang (login, admin/*, sau này teacher/*, student/*) import
   từ file này. Không tạo client riêng ở từng trang.

   Cách kết nối:
   1. Tạo project tại supabase.com, chạy supabase/schema.sql
   2. Project Settings → API → copy Project URL + anon public key
   3. Dán vào 2 hằng số bên dưới
   ============================================================ */
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

export const SUPABASE_URL = 'https://kkyiczvvagjkkcsyzanh.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtreWljenZ2YWdqa2tjc3l6YW5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwOTM3MTUsImV4cCI6MjEwMzY2OTcxNX0.I6MN78SGqAp1-HxfER7rbhC-OtoDped95D6jDurA42k';

if(!SUPABASE_URL || SUPABASE_URL.includes('YOUR_SUPABASE') || !SUPABASE_ANON_KEY || SUPABASE_ANON_KEY.includes('YOUR_SUPABASE')){
  throw new Error('Chưa cấu hình Supabase: mở assets/js/supabaseClient.js và dán SUPABASE_URL / SUPABASE_ANON_KEY từ Project Settings → API.');
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
});

export const ROLE_LABEL = { admin: 'Quản trị viên', teacher: 'Giáo viên', student: 'Học sinh' };
