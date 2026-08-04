import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// One message a user composed while offline (or during a failed send), waiting to
/// be delivered. Keyed by [clientMessageId] so a flush after reconnect is idempotent
/// server-side even if the same row is retried.
class QueuedMessage {
  final String clientMessageId;
  final int conversationId;
  final String body;
  final int? replyToMessageId;
  final int attempts;
  final DateTime createdAt;

  QueuedMessage({
    required this.clientMessageId,
    required this.conversationId,
    required this.body,
    this.replyToMessageId,
    this.attempts = 0,
    required this.createdAt,
  });

  factory QueuedMessage.fromRow(Map<String, dynamic> r) => QueuedMessage(
        clientMessageId: r['clientMessageId'] as String,
        conversationId: r['conversationId'] as int,
        body: r['body'] as String,
        replyToMessageId: r['replyToMessageId'] as int?,
        attempts: r['attempts'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['createdAt'] as int),
      );
}

/// Durable outbound queue for the messenger. Survives app restarts, so a message
/// typed in a dead-zone is not lost when the user backgrounds the app before
/// coverage returns. The idempotent send contract (server dedupes on
/// clientMessageId) makes at-least-once flushing safe.
class OfflineQueue {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'messenger_outbox.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE outbox (
            clientMessageId   TEXT PRIMARY KEY,
            conversationId    INTEGER NOT NULL,
            body              TEXT NOT NULL,
            replyToMessageId  INTEGER,
            attempts          INTEGER NOT NULL DEFAULT 0,
            createdAt         INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> enqueue(QueuedMessage m) async {
    final db = await _open();
    await db.insert(
      'outbox',
      {
        'clientMessageId': m.clientMessageId,
        'conversationId': m.conversationId,
        'body': m.body,
        'replyToMessageId': m.replyToMessageId,
        'attempts': m.attempts,
        'createdAt': m.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String clientMessageId) async {
    final db = await _open();
    await db.delete('outbox', where: 'clientMessageId = ?', whereArgs: [clientMessageId]);
  }

  Future<void> markAttempt(String clientMessageId) async {
    final db = await _open();
    await db.rawUpdate(
      'UPDATE outbox SET attempts = attempts + 1 WHERE clientMessageId = ?',
      [clientMessageId],
    );
  }

  /// Pending messages, oldest first, so a thread's queued messages flush in order.
  Future<List<QueuedMessage>> pending({int? conversationId}) async {
    final db = await _open();
    final rows = await db.query(
      'outbox',
      where: conversationId != null ? 'conversationId = ?' : null,
      whereArgs: conversationId != null ? [conversationId] : null,
      orderBy: 'createdAt ASC',
    );
    return rows.map(QueuedMessage.fromRow).toList();
  }

  Future<int> count() async {
    final db = await _open();
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM outbox');
    return (r.first['n'] as int?) ?? 0;
  }

  /// Drops every queued send. Called on logout: the outbox is keyed only by
  /// conversation, so anything left here would flush under the next user's token
  /// and post as the wrong person.
  Future<void> clear() async {
    final db = await _open();
    await db.delete('outbox');
  }
}
