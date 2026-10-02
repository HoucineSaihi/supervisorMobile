/// Server limit on a conversation title (Conversation.Title is nvarchar(200)).
const groupNameMax = 200;

/// A ready-to-use group name from its members — "Ali, Sara, Karim" or
/// "Ali, Sara, Karim +2" — so creating a group doesn't stall on naming it. Mirrors
/// the web's group-name.ts.
///
/// The name is shared by every member, so it lists the others by name and never says
/// "you". Callers pre-fill it only while the user hasn't typed their own.
String suggestGroupName(Iterable<String?> names, {int shown = 3}) {
  final clean = names.map((n) => (n ?? '').trim()).where((n) => n.isNotEmpty).toList();
  if (clean.isEmpty) return '';
  final head = clean.take(shown).join(', ');
  final rest = clean.length - shown;
  final name = rest > 0 ? '$head +$rest' : head;
  return name.length > groupNameMax ? name.substring(0, groupNameMax) : name;
}
