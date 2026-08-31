/* services/accountService.js — quản lý tài khoản (profiles). */
import { supabase, ROLE_LABEL } from '../assets/js/supabaseClient.js';

export async function listAccounts(){
  const { data, error } = await supabase.from('profiles').select('id, full_name, email, role, is_active').order('full_name');
  if(error) throw new Error(error.message);
  return data.map(p => ({ ...p, roleLabel: ROLE_LABEL[p.role] || p.role }));
}

export async function setAccountActive(id, isActive){
  const { error } = await supabase.from('profiles').update({ is_active: isActive }).eq('id', id);
  if(error) throw new Error(error.message);
}
