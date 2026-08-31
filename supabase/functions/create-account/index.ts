// supabase/functions/create-account/index.ts
// Edge Function chạy trên server của Supabase — ĐÂY LÀ NƠI DUY NHẤT được
// dùng service_role key để tạo tài khoản Auth mới. Frontend không bao giờ
// được cầm service_role key.
//
// Triển khai: supabase functions deploy create-account
// Gọi từ frontend qua: supabase.functions.invoke('create-account', { body: {...} })

import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    // 1. Xác thực người gọi function này CHÍNH LÀ một Admin đang đăng nhập.
    const authHeader = req.headers.get("Authorization") ?? "";
    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user: caller } } = await callerClient.auth.getUser();
    if (!caller) return json({ error: "Chưa đăng nhập." }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: callerProfile } = await admin
      .from("profiles").select("role").eq("id", caller.id).single();
    if (!callerProfile || callerProfile.role !== "admin") {
      return json({ error: "Chỉ Admin mới được cấp tài khoản mới." }, 403);
    }

    // 2. Tạo user Auth mới + gửi email mời đặt mật khẩu.
    const { email, full_name, role } = await req.json();
    if (!email || !full_name || !role) return json({ error: "Thiếu dữ liệu." }, 400);

    const { data: created, error: createErr } = await admin.auth.admin.inviteUserByEmail(email);
    if (createErr) return json({ error: createErr.message }, 400);

    // 3. Tạo hồ sơ trong bảng profiles với role thật — KHÔNG nhận role từ client
    //    theo kiểu tin tưởng mù quáng; role này do chính Admin đã xác thực ở bước 1 chọn.
    const { error: profileErr } = await admin.from("profiles").insert({
      id: created.user.id, full_name, email, role, is_active: true,
    });
    if (profileErr) return json({ error: profileErr.message }, 400);

    return json({ ok: true, id: created.user.id });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
