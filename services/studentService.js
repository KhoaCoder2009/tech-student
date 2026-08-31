/* services/studentService.js — TOÀN BỘ CRUD học sinh đi qua đây.
   Không trang nào được giữ mảng `students` cục bộ làm nguồn sự thật —
   sau insert/update/delete phải gọi lại list()/get() để lấy dữ liệu mới
   từ database (revalidate), UI chỉ là bản phản chiếu tạm thời. */
import { supabase } from '../assets/js/supabaseClient.js';

const SELECT_FIELDS = 'id, student_code, dob, gender, group_id, discipline_score, attendance_rate, profiles:profiles(full_name), student_positions(positions(label), groups(id))';

function normalizeRow(row){
  // Chuẩn hoá 1 dòng từ Supabase (join nhiều bảng) về hình dạng phẳng UI cần.
  const pos = row.student_positions?.[0]?.positions?.label || 'Thành viên';
  return {
    id: row.id,
    code: row.student_code,
    name: row.profiles?.full_name || '(chưa đặt tên)',
    gender: row.gender,
    dob: row.dob,
    group_id: row.group_id,
    position: pos,
    score: row.discipline_score ?? 0,
    attendance: row.attendance_rate ?? 0,
  };
}

export async function listStudents({ groupId = 'all', search = '', sort = 'name' } = {}){
  let query = supabase.from('students').select(SELECT_FIELDS);
  
  if(groupId !== 'all') query = query.eq('group_id', groupId);
  if(search.trim()) query = query.or(`student_code.ilike.%${search.trim()}%,profiles.full_name.ilike.%${search.trim()}%`);
  
  const { data, error } = await query;
  if(error) throw new Error(error.message);
  
  const rows = data.map(normalizeRow);
  const cmp = {
    name: (a,b) => a.name.localeCompare(b.name,'vi'),
    code: (a,b) => a.code.localeCompare(b.code),
    score: (a,b) => b.score - a.score,
    attendance: (a,b) => b.attendance - a.attendance,
  };
  rows.sort(cmp[sort] || cmp.name);
  return rows;
}

export async function getStudent(id){
  const { data, error } = await supabase.from('students').select(SELECT_FIELDS).eq('id', id).single();
  if(error) throw new Error(error.message);
  return normalizeRow(data);
}

export async function createStudent({ name, code, gender, group_id, position, dob }){
  // Production thật: học sinh phải có tài khoản Auth trước (qua createAccount),
  // sau đó tạo dòng trong `students` gắn với id đó. Ở đây giả định profile đã tồn tại
  // (được tạo bởi Edge Function create-account) và ta chỉ cập nhật hồ sơ lớp/tổ/chức vụ.
  const { data, error } = await supabase.from('students')
    .insert({ student_code: code, gender, dob, group_id }).select().single();
  if(error) throw new Error(error.message);
  
  // Cập nhật chức vụ nếu có
  if(position && position !== 'Thành viên'){
    const { error: posError } = await supabase.rpc('update_student_position', {
      p_student_id: data.id,
      p_position_label: position
    });
    if(posError) console.warn('Failed to update position:', posError);
  }
  
  return getStudent(data.id);
}

export async function updateStudent(id, { name, code, gender, group_id, position, dob }){
  const { error: sErr } = await supabase.from('students')
    .update({ student_code: code, gender, dob, group_id }).eq('id', id);
  if(sErr) throw new Error(sErr.message);
  
  if(name){
    const { error: pErr } = await supabase.from('profiles').update({ full_name: name }).eq('id', id);
    if(pErr) throw new Error(pErr.message);
  }
  
  // Cập nhật chức vụ nếu có
  if(position){
    const { error: posError } = await supabase.rpc('update_student_position', {
      p_student_id: id,
      p_position_label: position
    });
    if(posError) console.warn('Failed to update position:', posError);
  }
  
  return getStudent(id);
}

export async function deleteStudent(id){
  const { error } = await supabase.from('students').delete().eq('id', id);
  if(error) throw new Error(error.message);
}
