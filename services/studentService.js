/* services/studentService.js — TOÀN BỘ CRUD học sinh đi qua đây.
   Không trang nào được giữ mảng `students` cục bộ làm nguồn sự thật —
   sau insert/update/delete phải gọi lại list()/get() để lấy dữ liệu mới
   từ database (revalidate), UI chỉ là bản phản chiếu tạm thời. */
import { supabase } from '../assets/js/supabaseClient.js';

// Select fields aligned with actual schema
const SELECT_FIELDS = 'id, student_code, gender, dob, date_of_birth, class_id, group_id, discipline_score, attendance_rate, profiles:profiles(full_name), student_positions(positions(label), groups(id))';

function normalizeRow(row){
  // Chuẩn hoá 1 dòng từ Supabase (join nhiều bảng) về hình dạng phẳng UI cần.
  const positions = (row.student_positions || [])
    .map(p => p?.positions?.label)
    .filter(Boolean)
    .map(label => String(label).trim());

  const pos = positions.find(label => label !== 'Thành viên') || positions[0] || 'Thành viên';

  return {
    id: row.id,
    code: row.student_code,
    name: row.profiles?.full_name || '(chưa đặt tên)',
    gender: row.gender,
    dob: row.dob || row.date_of_birth, // Use dob first, fallback to date_of_birth
    class_id: row.class_id,
    group_id: row.group_id,
    position: pos,
    score: row.discipline_score ?? 85, // Default 85 as per schema
    attendance: row.attendance_rate ?? 95, // Default 95 as per schema
  };
}

export async function listStudents({ groupId = 'all', search = '', sort = 'name' } = {}){
  let query = supabase.from('students').select(SELECT_FIELDS);
  
  if(groupId !== 'all') query = query.eq('group_id', groupId);
  
  // Search: Supabase không hỗ trợ OR với nested relations, phải filter client-side
  const { data, error } = await query;
  if(error) throw new Error(error.message);
  
  let rows = data.map(normalizeRow);
  
  // Client-side search filter
  if(search.trim()) {
    const term = search.trim().toLowerCase();
    rows = rows.filter(s => 
      s.code.toLowerCase().includes(term) || 
      s.name.toLowerCase().includes(term)
    );
  }
  
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
  const insertData = { student_code: code, gender, group_id };
  // Schema has both dob and date_of_birth - set both for compatibility
  if (dob) {
    insertData.dob = dob;
    insertData.date_of_birth = dob;
  }
  
  const { data, error } = await supabase.from('students')
    .insert(insertData).select().single();
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
  const updateData = { student_code: code, gender, group_id };
  // Schema has both dob and date_of_birth - update both
  if (dob) {
    updateData.dob = dob;
    updateData.date_of_birth = dob;
  }
  
  const { error: sErr } = await supabase.from('students')
    .update(updateData).eq('id', id);
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

/**
 * Get current logged-in student's data
 * Used by student dashboard and profile pages
 */
export async function getCurrentStudent(){
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  
  return getStudent(user.id);
}

/**
 * Get students by class ID
 * Used by teacher dashboard to see their homeroom students
 */
export async function getStudentsByClass(classId){
  const { data, error } = await supabase.from('students').select(SELECT_FIELDS).eq('class_id', classId);
  if(error) throw new Error(error.message);
  return data.map(normalizeRow);
}
