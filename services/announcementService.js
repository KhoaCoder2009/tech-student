import { supabase } from '../assets/js/supabaseClient.js';

/**
 * Get all announcements for a class (grouped by position)
 */
export async function listAnnouncements(classId, options = {}) {
  const { position = null } = options;
  
  let query = supabase
    .from('announcements_with_author')
    .select('*')
    .eq('class_id', classId)
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false });

  if (position) {
    query = query.eq('created_by_position', position);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data || [];
}

/**
 * Get a single announcement by ID
 */
export async function getAnnouncement(id) {
  const { data, error } = await supabase
    .from('announcements_with_author')
    .select('*')
    .eq('id', id)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Check if user can post announcements
 */
export async function canPostAnnouncement(classId) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return false;

  const { data, error } = await supabase
    .rpc('can_post_announcement', {
      p_user_id: user.id,
      p_class_id: classId
    });

  if (error) {
    console.error('Error checking permissions:', error);
    return false;
  }
  
  return data === true;
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

  if (error) throw error;
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
  
  const positions = {
    'GVCN': [],
    'Lớp trưởng': [],
    'Bí thư': [],
    'Phó học tập': [],
    'Phó lao động': [],
    'Khác': []
  };
  
  announcements.forEach(a => {
    const pos = a.position_label || 'Khác';
    if (positions[pos]) {
      positions[pos].push(a);
    } else {
      positions['Khác'].push(a);
    }
  });
  
  return positions;
}
