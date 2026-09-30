import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// On-device snapshot of what the messenger last showed: the inbox's first page and
/// the latest messages of the most recent threads, stored as the server's own JSON.
///
/// Used only to paint instantly — on a cold start or when reopening a thread — while
/// the network request runs. The server response always replaces it, so the cache can
/// be stale without ever being wrong for long, and never needs its own sync logic.
///
/// A separate database file from the offline outbox on purpose: the outbox holds
/// unsent user data and must never be put at risk by a cache schema change.
class MessengerLocalCache {
  MessengerLocalCache._();
  static final MessengerLocalCache instance = MessengerLocalCache._();

  /// Threads kept per user; older ones are dropped on write.
  static const int _maxThreads = 10;

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'messenger_cache.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE snapshot (
            key        TEXT PRIMARY KEY,
            json       TEXT NOT NULL,
            updatedAt  INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  static String _inboxKey(int userId) => 'inbox:$userId';
  static String _threadPrefix(int userId) => 'thread:$userId:';
  static String _threadKey(int userId, int conversationId) => '${_threadPrefix(userId)}$conversationId';

  Future<Map<String, dynamic>?> getInbox(int userId) => _get(_inboxKey(userId));

  Future<void> putInbox(int userId, Map<String, dynamic> response) => _put(_inboxKey(userId), response);

  Future<Map<String, dynamic>?> getThread(int userId, int conversationId) =>
      _get(_threadKey(userId, conversationId));

  Future<void> putThread(int userId, int conversationId, Map<String, dynamic> page) async {
    await _put(_threadKey(userId, conversationId), page);
    try {
      final db = await _open();
      // Keep only the most recently opened threads for this user.
      await db.rawDelete(
        'DELETE FROM snapshot WHERE key LIKE ? AND key NOT IN '
        '(SELECT key FROM snapshot WHERE key LIKE ? ORDER BY updatedAt DESC LIMIT ?)',
        ['${_threadPrefix(userId)}%', '${_threadPrefix(userId)}%', _maxThreads],
      );
    } catch (_) {}
  }

  Future<void> removeThread(int userId, int conversationId) async {
    try {
      final db = await _open();
      await db.delete('snapshot', where: 'key = ?', whereArgs: [_threadKey(userId, conversationId)]);
    } catch (_) {}
  }

  /// Everything, for every account — called on logout.
  Future<void> clear() async {
    try {
      final db = await _open();
      await db.delete('snapshot');
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _get(String key) async {
    try {
      final db = await _open();
      final rows = await db.query('snapshot', columns: ['json'], where: 'key = ?', whereArgs: [key], limit: 1);
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
    } catch (_) {
      return null; // a corrupt or missing snapshot just means "no instant paint"
    }
  }

  Future<void> _put(String key, Map<String, dynamic> value) async {
    try {
      final db = await _open();
      await db.insert(
        'snapshot',
        {'key': key, 'json': jsonEncode(value), 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}
