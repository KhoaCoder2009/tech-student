/* services/seatingService.js — sơ đồ chỗ ngồi, dữ liệu thật từ bảng seating_positions. */
import { supabase } from '../assets/js/supabaseClient.js';

export async function listSeating(){
  const { data, error } = await supabase
    .from('seating_positions')
    .select('id, seat_row, seat_col, group_id, student_id, students(student_code, gender, profiles(full_name))');
  if(error) throw new Error(error.message);
  return data.map(r => ({
    id: r.id,
    seatRow: r.seat_row,
    seatCol: r.seat_col,
    groupId: r.group_id,
    studentId: r.student_id,
    code: r.students?.student_code,
    gender: r.students?.gender,
    name: r.students?.profiles?.full_name,
  }));
}

/** Gán 1 học sinh vào 1 ô ghế trong 1 tổ. Tự xoá chỗ ngồi cũ của học sinh đó (nếu có)
    vì 1 học sinh chỉ ngồi 1 chỗ tại 1 thời điểm (ràng buộc unique(student_id) ở DB). */
export async function assignSeat({ classId, groupId, studentId, seatRow, seatCol }){
  await supabase.from('seating_positions').delete().eq('student_id', studentId);
  const { error } = await supabase.from('seating_positions').upsert(
    { class_id: classId, group_id: groupId, student_id: studentId, seat_row: seatRow, seat_col: seatCol },
    { onConflict: 'group_id,seat_row,seat_col' }
  );
  if(error) throw new Error(error.message);
}

export async function clearSeat(seatId){
  const { error } = await supabase.from('seating_positions').delete().eq('id', seatId);
  if(error) throw new Error(error.message);
}
