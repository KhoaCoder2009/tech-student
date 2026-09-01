/* services/disciplineService.js — Quản lý nề nếp (lịch sử vi phạm và điểm) */
import { supabase } from '../assets/js/supabaseClient.js';

function normalizeDisciplineSchemaError(error) {
  const message = String(error?.message || '');
  if (message.includes('does not exist') || message.includes('relation') || message.includes('not found')) {
    throw new Error('Nề nếp: chưa chạy SQL setup của bảng discipline trong Supabase.');
  }
  throw new Error(error.message || 'Không thể tải dữ liệu nề nếp.');
}

/**
 * Danh mục mặc định để UI cũ của trang lịch sử nề nếp không crash.
 * Nếu hệ thống có bảng category riêng, có thể thay bằng query dữ liệu thật.
 */
export function listCategories() {
  return [
    { id: 'reward-study', label: 'Học tập tốt', type: 'add', default_points: 2 },
    { id: 'reward-behavior', label: 'Tuyên dương', type: 'add', default_points: 2 },
    { id: 'reward-discipline', label: 'Thực hiện nội quy', type: 'add', default_points: 1 },
    { id: 'violation-late', label: 'Đi muộn', type: 'subtract', default_points: 2 },
    { id: 'violation-uniform', label: 'Chưa đúng đồng phục', type: 'subtract', default_points: 2 },
    { id: 'violation-rules', label: 'Vi phạm nội quy', type: 'subtract', default_points: 3 },
  ];
}

/**
 * Lấy lịch sử vi phạm nề nếp
 */
export async function listDisciplineLogs({ studentId, dateFrom, dateTo } = {}) {
  let query = supabase
    .from('discipline_logs')
    .select(`
      id,
      type,
      points,
      reason,
      date,
      created_at,
      student:students(id, student_code, profiles(full_name)),
      recorded_by_profile:profiles!recorded_by(full_name),
      category:discipline_categories(label)
    `)
    .order('created_at', { ascending: false });

  if (studentId) query = query.eq('student_id', studentId);
  if (dateFrom) query = query.gte('created_at', dateFrom);
  if (dateTo) query = query.lte('created_at', dateTo);

  const { data, error } = await query;
  if (error) normalizeDisciplineSchemaError(error);

  return data.map(row => {
    const points = Math.abs(Number(row.points_deducted || 0));
    const isSubtract = Number(row.points_deducted || 0) < 0 || /muộn|vi phạm|không|chưa|đúng|trừ/i.test(String(row.violation_type || ''));

    return {
      id: row.id,
      violationType: row.violation_type,
      pointsDeducted: row.points_deducted,
      description: row.description,
      studentId: row.student?.id,
      studentCode: row.student?.student_code,
      studentName: row.student?.profiles?.full_name || '(chưa rõ)',
      recordedBy: row.recorded_by_profile?.full_name || 'Hệ thống',
      createdAt: row.created_at,
      date: row.created_at,
      type: isSubtract ? 'subtract' : 'add',
      points,
      reason: row.description || row.violation_type,
      categoryLabel: row.violation_type,
    };
  });
}

/**
 * Lấy thống kê nề nếp của một học sinh
 */
export async function getStudentDisciplineStats(studentId) {
  // Get current score from students table
  const { data: student, error: studentError } = await supabase
    .from('students')
    .select('discipline_score')
    .eq('id', studentId)
    .single();

  if (studentError) normalizeDisciplineSchemaError(studentError);

  // Get all violations
  const { data: logs, error: logsError } = await supabase
    .from('discipline_logs')
    .select('points_deducted')
    .eq('student_id', studentId);

  if (logsError) normalizeDisciplineSchemaError(logsError);

  const totalDeducted = logs.reduce((sum, r) => sum + parseFloat(r.points_deducted), 0);
  const violationCount = logs.length;

  return {
    currentScore: student?.discipline_score || 100,
    totalDeducted: totalDeducted.toFixed(1),
    violationCount,
    averageDeduction: violationCount > 0 ? (totalDeducted / violationCount).toFixed(1) : '0',
  };
}

/**
 * Thêm log vi phạm nề nếp
 * Hỗ trợ cả contract mới: { studentId, violationType, pointsDeducted, description, recordedBy }
 * và contract cũ của trang admin: { studentId, categoryId, type, points, reason, date, recordedBy }
 */
export async function createDisciplineLog(payload = {}) {
  const {
    studentId,
    violationType,
    pointsDeducted,
    description,
    recordedBy,
    categoryId,
    type,
    points,
    reason,
    date,
  } = payload;

  const normalizedType = type === 'subtract' ? 'subtract' : 'add';
  const normalizedPoints = Number(pointsDeducted ?? points ?? 0);
  const finalPoints = normalizedType === 'subtract' ? -Math.abs(normalizedPoints) : Math.abs(normalizedPoints);
  const finalViolationType = violationType || categoryId || (normalizedType === 'subtract' ? 'Trừ điểm' : 'Cộng điểm');
  const finalDescription = description || reason || finalViolationType;

  const { data, error } = await supabase
    .from('discipline_logs')
    .insert({
      student_id: studentId,
      violation_type: finalViolationType,
      points_deducted: finalPoints,
      description: finalDescription,
      created_by: recordedBy,
      created_at: date ? new Date(date).toISOString() : undefined,
    })
    .select()
    .single();

  if (error) normalizeDisciplineSchemaError(error);

  await updateStudentScore(studentId);

  return data;
}

/**
 * Xóa log vi phạm
 */
export async function deleteDisciplineLog(id, studentId) {
  const { error } = await supabase
    .from('discipline_logs')
    .delete()
    .eq('id', id);

  if (error) normalizeDisciplineSchemaError(error);

  // Recalculate student's score
  if (studentId) await updateStudentScore(studentId);
}

/**
 * Cập nhật điểm nề nếp của học sinh (tính lại từ logs)
 */
async function updateStudentScore(studentId) {
  const { data: logs, error } = await supabase
    .from('discipline_logs')
    .select('points_deducted')
    .eq('student_id', studentId);

  if (error) return;

  const totalDeducted = logs.reduce((sum, r) => sum + parseFloat(r.points_deducted || 0), 0);
  const newScore = Math.max(0, 100 - totalDeducted);

  await supabase
    .from('students')
    .update({ discipline_score: newScore })
    .eq('id', studentId);
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
