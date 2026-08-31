/* services/positionService.js — danh mục chức vụ DUY NHẤT cho toàn hệ thống. */
import { supabase } from '../assets/js/supabaseClient.js';

export async function listPositions(){
  const { data, error } = await supabase.from('positions').select('label').order('label');
  if(error) throw new Error(error.message);
  return data.map(p => p.label);
}
