import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/message.dart';
import 'messenger_service.dart';

/// Messenger media variants served by the content route.
enum MediaVariant { thumb, full }

/// On-device cache for messenger media: disk (size-capped, least-recently-used out
/// first) with a small in-memory layer on top for what's on screen right now.
///
/// Replaces AuthImage's old unbounded static map, which held every image ever viewed
/// in RAM for the whole session and re-downloaded all of it after every restart.
/// Keyed by attachment id + variant, so a thumbnail and its original never collide
/// and a re-signed or re-routed URL still hits the same entry.
///
/// Downloads go through Dio, whose interceptor adds the bearer token — so the app
/// asks for `?v=thumb` / `?v=full` directly and needs no signed link.
class MediaCache {
  MediaCache._();
  static final MediaCache instance = MediaCache._();

  static const int _maxDiskBytes = 150 * 1024 * 1024;
  static const int _maxMemoryEntries = 30;
  /// Trim the disk cache every N writes rather than listing the folder on each one.
  static const int _trimEvery = 20;

  final _service = MessengerService();
  final LinkedHashMap<String, Uint8List> _memory = LinkedHashMap();
  final Map<String, Future<File>> _inFlight = {};
  Directory? _dir;
  int _writesSinceTrim = 0;

  Future<Directory> _root() async {
    final dir = _dir ??= Directory(p.join((await getTemporaryDirectory()).path, 'msg_media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// The thumbnail is only worth a separate entry when the server made one; otherwise
  /// the "thumb" route serves the original anyway, so share the full-size entry.
  static MediaVariant effectiveVariant(MessageAttachment a, MediaVariant wanted) =>
      wanted == MediaVariant.thumb && a.thumbnailUrl == null ? MediaVariant.full : wanted;

  static String _route(MessageAttachment a, MediaVariant v) =>
      'api/Conversations/attachments/${a.id}/content?v=${v.name}';

  /// Local file for an attachment variant, downloading it once if needed.
  /// Concurrent requests for the same entry share one download.
  Future<File> file(MessageAttachment a, {MediaVariant variant = MediaVariant.full, String extension = ''}) async {
    final v = effectiveVariant(a, variant);
    final key = '${a.id}_${v.name}$extension';
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _fetch(a, v, key);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<File> _fetch(MessageAttachment a, MediaVariant v, String key) async {
    final f = File(p.join((await _root()).path, key));
    if (await f.exists()) {
      // LRU touch: eviction goes by last-modified time.
      f.setLastModified(DateTime.now()).catchError((_) => f);
      return f;
    }
    final bytes = await _service.downloadAttachment(_route(a, v));
    if (bytes.isEmpty) throw const FileSystemException('empty media response');
    await f.writeAsBytes(bytes, flush: true);
    if (++_writesSinceTrim >= _trimEvery) {
      _writesSinceTrim = 0;
      _trim();
    }
    return f;
  }

  /// Bytes for rendering, served from memory when the entry is on screen already.
  Future<Uint8List> bytes(MessageAttachment a, {MediaVariant variant = MediaVariant.thumb}) async {
    final key = '${a.id}_${effectiveVariant(a, variant).name}';
    final hit = _memory.remove(key);
    if (hit != null) {
      _memory[key] = hit; // move to most-recent
      return hit;
    }
    final data = await (await file(a, variant: variant)).readAsBytes();
    _memory[key] = data;
    while (_memory.length > _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
    return data;
  }

  /// Synchronous memory lookup — lets a rebuilt widget paint instantly with no flicker.
  Uint8List? peek(MessageAttachment a, {MediaVariant variant = MediaVariant.thumb}) =>
      _memory['${a.id}_${effectiveVariant(a, variant).name}'];

  /// Keeps the disk cache under its cap, evicting least-recently-used files first.
  Future<void> _trim() async {
    try {
      final entries = <File, FileStat>{};
      await for (final e in (await _root()).list()) {
        if (e is File) entries[e] = await e.stat();
      }
      var total = entries.values.fold<int>(0, (sum, s) => sum + s.size);
      if (total <= _maxDiskBytes) return;
      final oldestFirst = entries.entries.toList()
        ..sort((x, y) => x.value.modified.compareTo(y.value.modified));
      for (final e in oldestFirst) {
        if (total <= _maxDiskBytes * 0.8) break; // trim with headroom
        total -= e.value.size;
        await e.key.delete().catchError((_) => e.key);
      }
    } catch (_) {
      // Cache housekeeping must never break rendering.
    }
  }

  /// Drops everything — called on logout so the next account can't see this one's media.
  Future<void> clear() async {
    _memory.clear();
    try {
      final dir = await _root();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    _dir = null;
  }
}
