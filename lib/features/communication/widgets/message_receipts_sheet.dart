import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import '../services/messenger_service.dart';
import '../theme/comm_colors.dart';
import 'comm_avatar.dart';

/// "Seen by" sheet: who has read one of my messages and who hasn't.
///
/// Opened by tapping the receipt ticks on an own message. The server only answers
/// for the sender, so this is never reachable for someone else's message.
Future<void> showMessageReceipts(
  BuildContext context, {
  required int conversationId,
  required int messageId,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ReceiptsSheet(conversationId: conversationId, messageId: messageId),
  );
}

class _ReceiptsSheet extends StatefulWidget {
  final int conversationId;
  final int messageId;

  const _ReceiptsSheet({required this.conversationId, required this.messageId});

  @override
  State<_ReceiptsSheet> createState() => _ReceiptsSheetState();
}

class _ReceiptsSheetState extends State<_ReceiptsSheet> {
  static final _service = MessengerService();

  MessageReceipts? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getReceipts(widget.conversationId, widget.messageId);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load read status';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: CommColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  const Icon(Icons.done_all, size: 18, color: CommColors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Message info',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: CommColors.ink),
                  ),
                  const Spacer(),
                  if (_data != null)
                    Text(
                      '${_data!.readCount}/${_data!.recipientCount} read',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CommColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: CommColors.line2),
            Flexible(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: CommColors.blue)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: CommColors.muted, fontSize: 13.5)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final data = _data!;
    if (data.recipients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        child: Text(
          'No other members in this conversation yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CommColors.muted, fontSize: 13.5),
        ),
      );
    }

    final readers = data.readers;
    final pending = data.pending;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        if (readers.isNotEmpty) ...[
          _sectionHeader(Icons.done_all, 'Read by', readers.length, CommColors.blue),
          ...readers.map((r) => _row(r)),
        ],
        if (pending.isNotEmpty) ...[
          _sectionHeader(Icons.check, 'Not read yet', pending.length, CommColors.muted2),
          ...pending.map((r) => _row(r)),
        ],
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            '$label ($count)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _row(MessageReceiptEntry r) {
    final name = r.name ?? 'User ${r.caisseId}';
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: CommAvatar(name: name, seed: r.caisseId, size: 34, showPresence: false),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CommColors.ink),
      ),
      // Reads are stored as a position watermark rather than a timestamp, so a time
      // only exists for an explicit acknowledgement. Show the label alone otherwise.
      subtitle: r.readAt != null
          ? Text(
              DateFormat('dd/MM HH:mm').format(r.readAt!),
              style: const TextStyle(fontSize: 11.5, color: CommColors.muted2),
            )
          : null,
      trailing: r.hasAcknowledged
          ? const Icon(Icons.verified, size: 17, color: CommColors.green)
          : Icon(
              r.hasRead ? Icons.done_all : Icons.schedule,
              size: 16,
              color: r.hasRead ? CommColors.blue : CommColors.muted2,
            ),
    );
  }
}
