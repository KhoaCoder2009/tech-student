/* services/disciplineService.js — Quản lý nề nếp (cộng/trừ điểm) */
import { supabase } from '../assets/js/supabaseClient.js';

function normalizeDisciplineSchemaError(error) {
  const message = String(error?.message || '');
  if (message.includes('does not exist') || message.includes('relation') || message.includes('not found')) {
    throw new Error('Nề nếp: chưa chạy SQL setup của bảng discipline trong Supabase.');
  }
  throw new Error(error.message || 'Không thể tải dữ liệu nề nếp.');
}

/**
 * Lấy danh mục cộng/trừ điểm
 */
export async function listCategories() {
  const { data, error } = await supabase
    .from('discipline_categories')
    .select('*')
    .order('type')
    .order('label');

  if (error) normalizeDisciplineSchemaError(error);
  return data;
}

/**
 * Lấy lịch sử nề nếp
 */
export async function listDisciplineLogs({ studentId, dateFrom, dateTo, status = 'approved' } = {}) {
  let query = supabase
    .from('discipline_logs')
    .select(`
      id, type, points, reason, date, status, notes, created_at,
      student:students(id, student_code, profiles(full_name)),
      category:discipline_categories(label),
      recorded_by_profile:profiles!recorded_by(full_name)
    `)
    .order('date', { ascending: false });

  if (studentId) query = query.eq('student_id', studentId);
  if (dateFrom) query = query.gte('date', dateFrom);
  if (dateTo) query = query.lte('date', dateTo);
  if (status) query = query.eq('status', status);

  const { data, error } = await query;
  if (error) normalizeDisciplineSchemaError(error);

  return data.map(row => ({
    id: row.id,
    type: row.type,
    points: row.points,
    reason: row.reason,
    date: row.date,
    status: row.status,
    notes: row.notes,
    studentId: row.student?.id,
    studentCode: row.student?.student_code,
    studentName: row.student?.profiles?.full_name || '(chưa rõ)',
    categoryLabel: row.category?.label || 'Khác',
    recordedBy: row.recorded_by_profile?.full_name || 'Hệ thống',
    createdAt: row.created_at,
  }));
}

/**
 * Lấy thống kê nề nếp của một học sinh
 */
export async function getStudentDisciplineStats(studentId) {
  const { data, error } = await supabase
    .from('discipline_logs')
    .select('type, points')
    .eq('student_id', studentId)
    .eq('status', 'approved');

  if (error) normalizeDisciplineSchemaError(error);

  const totalAdd = data
    .filter(r => r.type === 'add')
    .reduce((sum, r) => sum + parseFloat(r.points), 0);

  const totalSubtract = data
    .filter(r => r.type === 'subtract')
    .reduce((sum, r) => sum + parseFloat(r.points), 0);

  const countAdd = data.filter(r => r.type === 'add').length;
  const countSubtract = data.filter(r => r.type === 'subtract').length;

  return {
    totalAdd: totalAdd.toFixed(1),
    totalSubtract: totalSubtract.toFixed(1),
    countAdd,
    countSubtract,
    currentScore: (100 + totalAdd - totalSubtract).toFixed(1),
  };
}

/**
 * Thêm log nề nếp (cộng/trừ điểm)
 */
export async function createDisciplineLog({
  studentId,
  categoryId,
  type,
  points,
  reason,
  date,
  recordedBy,
  status = 'approved',
  notes,
}) {
  const { data, error } = await supabase
    .from('discipline_logs')
    .insert({
      student_id: studentId,
      category_id: categoryId,
      type,
      points,
      reason,
      date: date || new Date().toISOString().split('T')[0],
      recorded_by: recordedBy,
      status,
      notes,
    })
    .select()
    .single();

  if (error) normalizeDisciplineSchemaError(error);
  return data;
}

/**
 * Cập nhật log nề nếp
 */
export async function updateDisciplineLog(id, updates) {
  const { data, error } = await supabase
    .from('discipline_logs')
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) normalizeDisciplineSchemaError(error);
  return data;
}

/**
 * Xóa log nề nếp
 */
export async function deleteDisciplineLog(id) {
  const { error } = await supabase
    .from('discipline_logs')
    .delete()
    .eq('id', id);

  if (error) normalizeDisciplineSchemaError(error);
}

/**
 * Duyệt/từ chối log nề nếp
 */
export async function approveDisciplineLog(id, approvedBy, status = 'approved') {
  return updateDisciplineLog(id, { status, approved_by: approvedBy });
}

/**
 * Lấy top học sinh theo điểm nề nếp
 */
export async function getTopStudentsByDiscipline(classId, limit = 10) {
  const { data, error } = await supabase
    .from('students')
    .select('id, student_code, discipline_score, profiles(full_name)')
    .eq('class_id', classId)
    .order('discipline_score', { ascending: false })
    .limit(limit);

  if (error) normalizeDisciplineSchemaError(error);

  return data.map(s => ({
    id: s.id,
    code: s.student_code,
    name: s.profiles?.full_name || '(chưa rõ)',
    score: s.discipline_score,
  }));
}
