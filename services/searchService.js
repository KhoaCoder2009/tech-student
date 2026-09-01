/* ============================================================
   SEARCH SERVICE - Universal search across students, groups, announcements
   ============================================================ */
import { supabase } from '../assets/js/supabaseClient.js';
import { getCurrentUser } from './authService.js';

/**
 * Universal search with relevance scoring
 */
export async function search(query, options = {}) {
  const {
    types = ['students', 'groups', 'announcements'],
    limit = 20,
    classId = null
  } = options;

  if (!query || query.trim().length < 2) {
    return [];
  }

  const searchTerm = query.trim().toLowerCase();
  const results = [];

  try {
    // Search students
    if (types.includes('students')) {
      const { data: students } = await supabase
        .from('students')
        .select('id, student_code, class_id, profiles(full_name)')
        .or(`student_code.ilike.%${searchTerm}%,profiles.full_name.ilike.%${searchTerm}%`)
        .limit(limit);

      if (students) {
        results.push(...students.map(s => ({
          type: 'student',
          id: s.id,
          title: s.profiles?.full_name || s.student_code,
          subtitle: `Mã: ${s.student_code}`,
          icon: '👤',
          url: `/admin/students-detail.html?id=${s.id}`,
          relevance: calculateRelevance(searchTerm, [s.profiles?.full_name, s.student_code])
        })));
      }
    }

    // Search groups
    if (types.includes('groups')) {
      const { data: groups } = await supabase
        .from('groups')
        .select('id, name, color')
        .ilike('name', `%${searchTerm}%`)
        .limit(limit);

      if (groups) {
        results.push(...groups.map(g => ({
          type: 'group',
          id: g.id,
          title: g.name,
          subtitle: 'Tổ học tập',
          icon: '🗂️',
          url: `/admin/groups.html?highlight=${g.id}`,
          relevance: calculateRelevance(searchTerm, [g.name])
        })));
      }
    }

    // Search announcements
    if (types.includes('announcements')) {
      const user = await getCurrentUser();
      if (user && classId) {
        const { data: announcements } = await supabase
          .from('announcements')
          .select('id, title, content, created_at')
          .eq('class_id', classId)
          .or(`title.ilike.%${searchTerm}%,content.ilike.%${searchTerm}%`)
          .order('created_at', { ascending: false })
          .limit(limit);

        if (announcements) {
          results.push(...announcements.map(a => ({
            type: 'announcement',
            id: a.id,
            title: a.title,
            subtitle: truncate(a.content, 60),
            icon: '📢',
            url: `/admin/announcements.html?id=${a.id}`,
            relevance: calculateRelevance(searchTerm, [a.title, a.content])
          })));
        }
      }
    }

    // Sort by relevance
    results.sort((a, b) => b.relevance - a.relevance);

    return results.slice(0, limit);
  } catch (error) {
    console.error('Search error:', error);
    return [];
  }
}

/**
 * Calculate search relevance score
 */
function calculateRelevance(query, fields) {
  const q = query.toLowerCase();
  let score = 0;

  fields.filter(Boolean).forEach(field => {
    const f = String(field).toLowerCase();
    
    // Exact match
    if (f === q) score += 100;
    
    // Starts with query
    else if (f.startsWith(q)) score += 50;
    
    // Contains query
    else if (f.includes(q)) score += 25;
    
    // Word starts with query
    const words = f.split(/\s+/);
    if (words.some(w => w.startsWith(q))) score += 40;
  });

  return score;
}

/**
 * Truncate text with ellipsis
 */
function truncate(text, length) {
  if (!text) return '';
  if (text.length <= length) return text;
  return text.substring(0, length) + '...';
}

/**
 * Get recent searches from localStorage
 */
export function getRecentSearches() {
  try {
    const recent = localStorage.getItem('recent-searches');
    return recent ? JSON.parse(recent) : [];
  } catch {
    return [];
  }
}

/**
 * Save search to recent
 */
export function saveRecentSearch(query) {
  if (!query || query.length < 2) return;
  
  try {
    const recent = getRecentSearches();
    const filtered = recent.filter(q => q !== query);
    filtered.unshift(query);
    
    // Keep only last 10
    const updated = filtered.slice(0, 10);
    localStorage.setItem('recent-searches', JSON.stringify(updated));
  } catch (error) {
    console.error('Failed to save recent search:', error);
  }
}

/**
 * Clear recent searches
 */
export function clearRecentSearches() {
  try {
    localStorage.removeItem('recent-searches');
  } catch (error) {
    console.error('Failed to clear recent searches:', error);
  }
}
