import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../VisualMerchandising/execution_screen.dart';
import '../../VisualMerchandising/services/vm_service.dart';
import '../../calendar/models/boutiqueModel.dart';
import '../../calendar/screens/widgets/missionDetails.dart';
import '../../incidents/screens/ConsultProblem.dart';
import '../models/conversation.dart';
import '../theme/comm_colors.dart';
import 'scope_visuals.dart';

/// Bottom sheet with what a scoped conversation is about — its status, key facts and
/// an "Open" button to the incident / campaign / execution / mission itself.
Future<void> showConversationContextSheet(BuildContext context, ConversationContext ctx) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _ContextSheet(ctx: ctx, hostContext: context),
  );
}

/// Opens the object a conversation is about on its own screen.
///
/// Campaigns are executed per store, so a campaign opens on one of the caller's own
/// stores — asked for when they have several in it.
Future<void> openScopeObject(BuildContext context, ConversationContext ctx) async {
  switch (ctx.scopeType) {
    case ConversationScopeType.incident:
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConsultProblem(problemId: ctx.scopeId),
      ));
      return;
    case ConversationScopeType.mission:
      await Navigator.of(context).push(MaterialPageRoute(
        // mode 1 + the mission's status, exactly as the calendar opens it.
        builder: (_) => MissionDetailsWidget(
          missionId: ctx.scopeId,
          mode: 1,
          status: ctx.missionStatus ?? 0,
        ),
      ));
      return;
    case ConversationScopeType.vmExecution:
      if (ctx.campaignId != null && ctx.siteId != null) {
        await _openCampaignAt(context, ctx.campaignId!, ctx.siteId!);
      }
      return;
    case ConversationScopeType.campaign:
      await _openCampaign(context, ctx.campaignId ?? ctx.scopeId, ctx.siteIds);
      return;
    default:
      return;
  }
}

Future<void> _openCampaign(BuildContext context, int campaignId, List<int> campaignSiteIds) async {
  final List<BoutiqueModel> mine;
  try {
    mine = await VmService().getBoutiquesByUserIds([]);
  } catch (_) {
    _snack('Could not load your stores.');
    return;
  }
  final candidates = mine.where((b) => campaignSiteIds.contains(b.id)).toList();
  if (candidates.isEmpty) {
    _snack('None of your stores is part of this campaign.');
    return;
  }
  if (!context.mounted) return;

  final site = candidates.length == 1 ? candidates.first : await _pickStore(context, candidates);
  if (site == null || !context.mounted) return;
  await _openCampaignAt(context, campaignId, site.id);
}

Future<void> _openCampaignAt(BuildContext context, int campaignId, int siteId) async {
  try {
    final page = await VmService().getCampaignsBySites([siteId], campaignId: campaignId);
    final campaign = page.data.where((c) => c.campaignId == campaignId).firstOrNull;
    if (campaign == null) {
      _snack('This campaign is not available for this store.');
      return;
    }
    await Get.to(
      () => ExecutionScreen(campaign: campaign, siteId: campaign.siteId > 0 ? campaign.siteId : siteId),
      transition: Transition.rightToLeft,
    );
  } catch (_) {
    _snack('Could not open the campaign.');
  }
}

Future<BoutiqueModel?> _pickStore(BuildContext context, List<BoutiqueModel> stores) {
  return showModalBottomSheet<BoutiqueModel>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Open the campaign for which store?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CommColors.ink)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: stores
                  .map((s) => ListTile(
                        leading: const Icon(Icons.storefront_outlined, color: CommColors.muted),
                        title: Text(s.libelle ?? 'Store #${s.id}'),
                        subtitle: s.code != null ? Text(s.code!) : null,
                        onTap: () => Navigator.of(ctx).pop(s),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

void _snack(String message) => Get.snackbar('Messenger', message, snackPosition: SnackPosition.BOTTOM);

String _openLabel(ConversationScopeType t) {
  switch (t) {
    case ConversationScopeType.incident:
      return 'Open incident';
    case ConversationScopeType.campaign:
      return 'Open campaign';
    case ConversationScopeType.vmExecution:
      return 'Open execution';
    case ConversationScopeType.mission:
      return 'Open mission';
    default:
      return 'Open';
  }
}

class _ContextSheet extends StatelessWidget {
  final ConversationContext ctx;

  /// The conversation screen's context: the sheet's own is gone once it pops, and
  /// navigation must happen from a context that is still mounted.
  final BuildContext hostContext;

  const _ContextSheet({required this.ctx, required this.hostContext});

  @override
  Widget build(BuildContext context) {
    final name = scopeTypeToJson(ctx.scopeType);
    final v = scopeVisualsFor(name);
    final status = ctx.status;

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: v.bg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(v.icon, color: v.fg, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              scopeLabelFor(name).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: v.fg,
                              ),
                            ),
                            if (status != null) ...[
                              const SizedBox(width: 8),
                              _StatusChip(status: status),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ctx.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: CommColors.ink),
                        ),
                        if (ctx.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            ctx.subtitle!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: CommColors.muted, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (ctx.fields.isNotEmpty || status?.closedAt != null) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: CommColors.line2),
                const SizedBox(height: 6),
                ...ctx.fields.map((f) => _FieldRow(label: f.label, value: _format(f))),
                if (status?.closedAt != null)
                  _FieldRow(label: 'Closed on', value: DateFormat('dd/MM/yyyy HH:mm').format(status!.closedAt!)),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: CommColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    openScopeObject(hostContext, ctx);
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(_openLabel(ctx.scopeType),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _format(ConversationContextField f) {
    switch (f.kind) {
      case 'date':
      case 'datetime':
        final d = DateTime.tryParse(f.value)?.toLocal();
        if (d == null) return f.value;
        return DateFormat(f.kind == 'date' ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm').format(d);
      case 'percent':
        return '${f.value} %';
      default:
        return f.value;
    }
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: CommColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CommColors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ScopeStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final fg = status.isClosed ? CommColors.muted : CommColors.blueDark;
    final bg = status.isClosed ? CommColors.line2 : CommColors.blueSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isClosed) ...[
            Icon(Icons.lock_outline, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(status.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
