import { supabase } from '../assets/js/supabaseClient.js';
import { getCurrentUser } from './authService.js';

function normalizeSchemaError(error, featureName) {
  const message = String(error?.message || '');
  if (message.includes('does not exist') || message.includes('relation') || message.includes('not found')) {
    throw new Error(`${featureName}: data chưa sẵn sàng trong Supabase. Hãy chạy SQL setup tương ứng trong SQL Editor.`);
  }
  throw error;
}

/**
 * Get all announcements for a class
 */
export async function listAnnouncements(classId, options = {}) {
  let query = supabase
    .from('announcements')
    .select(`
      *,
      author:profiles!created_by(full_name, role)
    `)
    .eq('class_id', classId)
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false });

  const { data, error } = await query;

  if (error) normalizeSchemaError(error, 'Thông báo');
  
  // Get author positions separately (student only)
  const dataWithPositions = await Promise.all((data || []).map(async (a) => {
    let position_label = 'Thành viên';
    let position_icon = '👤';
    let position_color = 'rgba(79, 109, 245, 0.12)';
    
    // If author is student, get their position
    if (a.author?.role === 'student') {
      const { data: positions } = await supabase
        .from('student_positions')
        .select('positions(label)')
        .eq('student_id', a.created_by)
        .limit(1);
      
      if (positions && positions.length > 0) {
        position_label = positions[0]?.positions?.label || 'Thành viên';
      }
      position_icon = '🎓';
      position_color = 'rgba(45, 183, 160, 0.12)';
    } else if (a.author?.role === 'teacher') {
      position_label = 'GVCN';
      position_icon = '👨‍🏫';
      position_color = 'rgba(242, 166, 75, 0.18)';
    } else if (a.author?.role === 'admin') {
      position_label = 'Admin';
      position_icon = '👨‍💼';
      position_color = 'rgba(217, 71, 80, 0.14)';
    }
    
    return {
      ...a,
      author_name: a.author?.full_name || 'Không rõ',
      author_role: a.author?.role || 'student',
      position_label,
      position_icon,
      position_color
    };
  }));
  
  return dataWithPositions;
}

/**
 * Get a single announcement by ID
 */
export async function getAnnouncement(id) {
  const { data, error } = await supabase
    .from('announcements')
    .select(`
      *,
      author:profiles!created_by(full_name),
      author_position:student_positions(positions(label))
    `)
    .eq('id', id)
    .single();

  if (error) throw error;
  
  return {
    ...data,
    author_name: data.author?.full_name || 'Không rõ',
    position_label: data.author_position?.[0]?.positions?.label || 'Thành viên'
  };
}

/**
 * Check if user can post announcements
 * Only GVCN, Lớp trưởng, Bí thư, Phó học tập, Phó lao động can post
 */
export async function canPostAnnouncement(classId) {
  const savedUser = await getCurrentUser();
  if (savedUser?.role === 'admin' || savedUser?.role === 'teacher') return true;

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return false;

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  if (profile?.role === 'admin' || profile?.role === 'teacher') return true;

  const { data: positions } = await supabase
    .from('student_positions')
    .select('positions(label)')
    .eq('student_id', user.id);

  if (!positions || positions.length === 0) return false;

  const allowedPositions = ['Lớp trưởng', 'Bí thư', 'Phó học tập', 'Phó lao động'];
  return positions.some(p => allowedPositions.includes(p.positions?.label));
}

/**
 * Create new announcement
 */
export async function createAnnouncement(classId, announcement) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  // Check permission first
  const canPost = await canPostAnnouncement(classId);
  if (!canPost) {
    throw new Error('Bạn không có quyền đăng thông báo. Chỉ GVCN, Lớp trưởng, Bí thư, Phó học tập, Phó lao động mới được đăng.');
  }

  const { data, error } = await supabase
    .from('announcements')
    .insert({
      class_id: classId,
      title: announcement.title,
      content: announcement.content,
      is_important: announcement.is_important || false,
      created_by: user.id
    })
    .select()
    .single();

  if (error) normalizeSchemaError(error, 'Thông báo');
  return data;
}

/**
 * Update announcement
 */
export async function updateAnnouncement(id, updates) {
  const { data, error } = await supabase
    .from('announcements')
    .update({
      title: updates.title,
      content: updates.content,
      is_important: updates.is_important,
      updated_at: new Date().toISOString()
    })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete announcement
 */
export async function deleteAnnouncement(id) {
  const { error } = await supabase
    .from('announcements')
    .delete()
    .eq('id', id);

  if (error) throw error;
}

/**
 * Pin/unpin announcement (GVCN only)
 */
export async function togglePinAnnouncement(id, isPinned) {
  const { data, error } = await supabase
    .from('announcements')
    .update({ is_pinned: isPinned })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get announcements grouped by position
 */
export async function getAnnouncementsByPosition(classId) {
  const announcements = await listAnnouncements(classId);
  
  const grouped = {
    'GVCN': [],
    'Lớp trưởng': [],
    'Bí thư': [],
    'Phó học tập': [],
    'Phó lao động': [],
    'Khác': []
  };
  
  announcements.forEach(a => {
    const pos = a.position_label || 'Khác';
    if (grouped[pos]) {
      grouped[pos].push(a);
    } else {
      grouped['Khác'].push(a);
    }
  });
  
  return grouped;
}
