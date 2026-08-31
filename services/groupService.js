/* services/groupService.js — nguồn dữ liệu tổ DUY NHẤT cho toàn hệ thống. */
import { supabase } from '../assets/js/supabaseClient.js';

export async function listGroups(){
  const { data, error } = await supabase.from('groups').select('id, name, color, class_id').order('name');
  if(error) throw new Error(error.message);
  return data;
}
