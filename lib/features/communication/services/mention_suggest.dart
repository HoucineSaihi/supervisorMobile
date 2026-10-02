import '../models/conversation.dart';
import '../models/message.dart';

/// Client half of @-mention autocomplete — mirrors the web's mention-suggest.ts.
///
/// Members are matched here, from the conversation detail already in memory, so the
/// people part of the menu appears on the same keystroke with no request. Only
/// incidents, missions, stores and campaigns go to the server (excludeUsers=true),
/// and their answers are cached so backspacing or retyping costs nothing.

/// Members shown at most — the rest of the menu is for entities.
const _maxMembers = 4;

/// Dart core has no Unicode normalization (NFD), and this isn't worth a package:
/// the names and labels here are French/Latin, so a fold table covers them.
const _accentFold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae', 'ß': 'ss',
};

final _nonAlnum = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lowercase with accents stripped — "Évry" → "evry". Same rule as the server.
String normalizeMention(String? value) {
  if (value == null || value.isEmpty) return '';
  final sb = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    sb.write(_accentFold[ch] ?? ch);
  }
  return sb.toString();
}

/// Word-prefix match, the same rule the server index uses: "@jea" and "@dup" both
/// find "Jean Dupont". A query spanning a separator ("jean-d") also matches the whole
/// value with separators dropped.
bool matchesMention(String query, List<String?> values) {
  final q = normalizeMention(query).replaceAll(_nonAlnum, '');
  if (q.isEmpty) return true;
  for (final v in values) {
    final n = normalizeMention(v);
    if (n.isEmpty) continue;
    if (n.split(_nonAlnum).any((w) => w.startsWith(q))) return true;
    if (n.replaceAll(_nonAlnum, '').startsWith(q)) return true;
  }
  return false;
}

/// Members matching the query, as suggestions. Excludes yourself. The inline @-menu
/// caps at a few so entities still fit; the picker passes a larger [max].
List<MentionSuggestion> filterMembers(
    List<ConversationMember>? members, String query, int selfId,
    {int max = _maxMembers}) {
  return (members ?? const <ConversationMember>[])
      .where((m) => m.caisseId != selfId && matchesMention(query, [m.name]))
      .take(max)
      .map((m) => MentionSuggestion(
            entityType: 'User',
            entityId: m.caisseId,
            label: (m.name?.isNotEmpty ?? false) ? m.name! : 'User #${m.caisseId}',
            context: m.roleName,
            token: '@[User:${m.caisseId}]',
          ))
      .toList();
}

/// Narrows a shorter query's results to a longer one ("@fu" → "@fui") while the real
/// request is in flight. Only a preview: the server also matches words of an
/// incident's description the label doesn't show, so its answer replaces this.
List<MentionSuggestion> refineMentions(List<MentionSuggestion> cached, String query) =>
    cached
        .where((s) => matchesMention(query, [s.label, s.context, '${s.entityId}']))
        .toList();

/// Small LRU of server answers keyed by query (one cache per conversation
/// controller), with a short TTL.
class MentionSuggestCache {
  MentionSuggestCache({this.maxEntries = 50, this.ttl = const Duration(seconds: 60)});

  final int maxEntries;
  final Duration ttl;

  // LinkedHashMap (the Map default) keeps insertion order, which tracks recency
  // because every hit is re-inserted.
  final _entries = <String, ({DateTime at, List<MentionSuggestion> list})>{};

  List<MentionSuggestion>? get(String query) {
    final key = normalizeMention(query);
    final hit = _entries.remove(key);
    if (hit == null) return null;
    if (DateTime.now().difference(hit.at) > ttl) return null;
    _entries[key] = hit;
    return hit.list;
  }

  void set(String query, List<MentionSuggestion> list) {
    final key = normalizeMention(query);
    _entries.remove(key);
    _entries[key] = (at: DateTime.now(), list: list);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Cached answer for the longest prefix of the query, for a refined preview.
  List<MentionSuggestion>? longestPrefix(String query) {
    final q = normalizeMention(query);
    for (var len = q.length - 1; len >= 0; len--) {
      final hit = get(q.substring(0, len));
      if (hit != null) return hit;
    }
    return null;
  }

  void clear() => _entries.clear();
}
