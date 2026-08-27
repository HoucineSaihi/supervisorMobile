import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/execution_controller.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/guideline_handler.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/submission_comments_sheet.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/execution_comments_button.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/executor_name_dialog.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/zone_row.dart';
import 'package:supervisormobile/features/VisualMerchandising/vm_l10n_helpers.dart';
import 'package:supervisormobile/features/VisualMerchandising/zone_detail_screen.dart';


class ExecutionScreen extends StatefulWidget {
  final VmCampaignDto campaign;
  final int siteId;

  const ExecutionScreen({super.key, required this.campaign, required this.siteId});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> {
  late final ExecutionController controller;

  /// Guards the start-of-campaign prompt so it is asked at most once per visit,
  /// even though [build] runs again on every observable change.
  bool _executorPromptHandled = false;

  VmCampaignDto get campaign => widget.campaign;
  int get siteId => widget.siteId;

  @override
  void initState() {
    super.initState();
    // On crée le controller ET on lui passe la campagne
    controller = Get.put(ExecutionController());
    _initAndPrompt();
  }

  /// Loads the execution, then asks who is executing when the campaign is being
  /// started and nobody has been named yet.
  Future<void> _initAndPrompt() async {
    await controller.init(campaign, siteId);
    if (!mounted || _executorPromptHandled) return;

    final status = controller.liveCampaign.value?.status ?? campaign.status;
    final isFinished = status == CampaignStatus.approved ||
        status == CampaignStatus.cancelled;

    // Only prompt while the work is still open: a campaign already approved or
    // cancelled is read-only, and re-asking there would be noise.
    if (isFinished || controller.hasExecutorName) {
      _executorPromptHandled = true;
      return;
    }

    _executorPromptHandled = true;
    final l10n = AppLocalizations.of(context)!;
    await _editExecutorName(context, controller, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Obx(() {
      final vm = controller.liveCampaign.value ?? campaign;
      return Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, controller, vm, l10n),
              _buildGuidelineBanner(context, l10n, vm),
              _buildZoneList(controller, l10n, vm),
            ],
          ),
        ),
      );
    });
  }

  // ── 1. Header avec progression globale ─────────────
  Widget _buildHeader(
    BuildContext context,
    ExecutionController controller,
    VmCampaignDto vm,
    AppLocalizations l10n,
  ) {
    final status = vm.status;
    final hasLocalPending = controller.zonePhotos.values.any(
      (photos) => photos.isNotEmpty,
    );
    final isLocalPendingOnly =
        hasLocalPending &&
            status != CampaignStatus.submitted &&
            status != CampaignStatus.approved &&
            status != CampaignStatus.disapproved;
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    Color dotColor;
    String statusLabel;
    if (isLocalPendingOnly) {
      dotColor = const Color(0xFFF5A623);
      statusLabel = _localPendingCampaignStatusLabel(isFrench);
    } else {
      switch (status) {
        case CampaignStatus.inProgress:
          dotColor = const Color(0xFF7EFFA0);
          statusLabel = l10n.inProgress;
          break;
        case CampaignStatus.submitted:
          dotColor = const Color(0xFFF5A623);
          statusLabel = l10n.completed;
          break;
        case CampaignStatus.approved:
          dotColor = const Color(0xFF27AE73);
          statusLabel = _approvedStatusLabel(isFrench);
          break;
        case CampaignStatus.disapproved:
          dotColor = const Color(0xFFE74C3C);
          statusLabel = _disapprovedStatusLabel(isFrench);
          break;
        case CampaignStatus.cancelled:
          dotColor = const Color(0xFFFF8A80);
          statusLabel = l10n.cancelled;
          break;
        case CampaignStatus.notStarted:
          dotColor = const Color(0xFFE2EEF8);
          statusLabel = l10n.planned;
          break;
        default:
          dotColor = const Color(0xFFB8D9F5);
          statusLabel = l10n.unknown;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // Réduire la hauteur globale du header.
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Bouton retour + bouton commentaires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, color: Colors.white70, size: 20),
                    Text(
                      l10n.vmBackToCampaigns,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final isLoading = controller.isLoadingExecution.value;
                    return GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => controller.loadExecution(
                                campaignId: vm.campaignId,
                                siteId: siteId,
                              ),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                      ),
                    );
                  }),
                  Obx(() {
                    final unread = controller.unreadCommentCount.value;
                    return ExecutionCommentsButton(
                      unreadCount: unread,
                      label: l10n.vmComments,
                      onTap: () async {
                        await SubmissionCommentsSheet.show(
                          context,
                          campaignId: vm.campaignId,
                          siteId: siteId,
                          campaignName: vm.libelle,
                          onThreadOpened: controller.markSubmissionCommentsRead,
                        );
                      },
                    );
                  }),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Titre campagne
          Text(
            vm.libelle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Exécutant : nom saisi au démarrage, modifiable via le crayon.
          _buildExecutorRow(context, controller, l10n),

          const SizedBox(height: 10),

          // Stats : 3 chips (hide completion % if not submitted)
          Obx(() {
            final zones = controller.zones;
            final completed = zones
                .where((z) => controller.isZoneComplete(z))
                .length;
            final approved = zones.where((z) => z.isApproved).length;
            final approvalPct = zones.isNotEmpty
                ? (approved / zones.length * 100).round()
                : 0;
            final limitDate = DateFormat('dd/MM/yyyy').format(vm.endDate);
            final status = controller.liveCampaign.value?.status ?? vm.status;
            final showCompletionPercentage = status == CampaignStatus.submitted ||
                status == CampaignStatus.approved ||
                status == CampaignStatus.disapproved;

            return Row(
              children: [
                if (showCompletionPercentage)
                  Expanded(
                    child: _HeaderChip(
                      value: '$approvalPct%',
                      label: l10n.vmCompletionLabel,
                    ),
                  ),
                if (showCompletionPercentage) const SizedBox(width: 8),
                Expanded(
                  child: _HeaderChip(
                    value: '$completed/${zones.length}',
                    label: l10n.vmZonesLabel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderChip(
                    // Afficher uniquement la date limite, sans indication "dépassée".
                    value: limitDate,
                    label: l10n.vmLimitLabel,
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(l10n.vmLimitDialogTitle),
                            content: Text(limitDate),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: Text(l10n.vmOk),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 10),

          // Barre d'approbation (hidden if not submitted)
          Obx(() {
            final status = controller.liveCampaign.value?.status ?? vm.status;
            final showProgress = status == CampaignStatus.submitted ||
                status == CampaignStatus.approved ||
                status == CampaignStatus.disapproved;

            if (!showProgress) return const SizedBox.shrink();

            final total = controller.zones.length;
            final approved = controller.zones.where((z) => z.isApproved).length;
            final approvalRatio = total > 0 ? approved / total : 0.0;
            final approvalPct = (approvalRatio * 100).round();

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.vmSupervisorReview,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$approved/$total · $approvalPct%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: approvalRatio,
                    minHeight: 7,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4FD38E),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── 2. Bannière guideline ───────────────────────────
  /// Shows the executor's name with a pen button to correct it.
  ///
  /// While no name is on record yet (campaigns started before this was
  /// introduced, or a failed first save) the row invites the user to add one.
  Widget _buildExecutorRow(
    BuildContext context,
    ExecutionController controller,
    AppLocalizations l10n,
  ) {
    return Obx(() {
      final name = controller.executorName.value.trim();
      final isSaving = controller.isSavingExecutorName.value;
      final hasName = name.isNotEmpty;

      return Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.white70, size: 15),
          const SizedBox(width: 6),
          Text(
            '${l10n.vmExecutorLabel} : ',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          Flexible(
            child: Text(
              hasName ? name : '—',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: hasName ? Colors.white : Colors.white54,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (isSaving)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          else
            GestureDetector(
              onTap: () => _editExecutorName(context, controller, l10n),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, color: Colors.white, size: 15),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _editExecutorName(
    BuildContext context,
    ExecutionController controller,
    AppLocalizations l10n,
  ) async {
    final current = controller.executorName.value.trim();
    final name = await ExecutorNameDialog.show(
      context,
      initialName: current,
      isEditing: current.isNotEmpty,
    );
    if (name == null) return;

    final saved = await controller.saveExecutorName(name);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vmExecutorSaveError)),
      );
    }
  }

  Widget _buildGuidelineBanner(
    BuildContext context,
    AppLocalizations l10n,
    VmCampaignDto vm,
  ) {
    if (!vm.containsGuideline) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        GuidelineHandler.openGuideline(context, vm);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB8D9F5), width: 1.5),
        ),
        child: Row(
          children: [
            // Icône PDF
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E5FAA).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.vmGuidelineVmBannerTitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3F72),
                    ),
                  ),
                  Text(
                    vm.firstGuideline?.guidelineName ?? l10n.vmGuidelineFallbackName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7BACD8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF4A9EDD),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Liste des zones (scrollable) ────────────────
  Widget _buildZoneList(
    ExecutionController controller,
    AppLocalizations l10n,
    VmCampaignDto vm,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Text(
              l10n.vmZonesToCompleteTitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7BACD8),
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingExecution.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1E5FAA)),
                );
              }
              // Dépendance explicite sur les photos locales pour forcer la
              // reconstruction de la liste et des compteurs par zone.
              final localPhotosTick = controller.zonePhotos.values.fold<int>(
                0,
                (sum, photos) => sum + photos.length,
              );

              final zones = controller.zones;
              if (zones.isEmpty) {
                return Center(
                  child: Text(
                    l10n.vmNoZonesFound,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7BACD8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  if (controller.executionError.value.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Text(
                        l10n.vmLiveDataUnavailable,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFC87700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      key: ValueKey('zones_${zones.length}_$localPhotosTick'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        return ZoneRow(
                          zone: zone,
                          isZoneValidated: controller.isZoneValidated(zone),
                          hasLocalPending: controller.hasLocalPending(zone),
                          totalPhotoCount: controller.totalPhotoCount(zone),
                          issueText: controller.zoneIssues[zone.zoneId],
                          onTap: () {
                            Get.to(
                              () => ZoneDetailScreen(
                                zone: zone,
                                campaign: vm,
                              ),
                              transition: Transition.rightToLeft,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _localPendingCampaignStatusLabel(bool isFrench) {
    return isFrench ? 'En cours localement' : 'In progress locally';
  }

  String _approvedStatusLabel(bool isFrench) {
    return isFrench ? 'Approuvee' : 'Approved';
  }

  String _disapprovedStatusLabel(bool isFrench) {
    return isFrench ? 'Desapprouvee' : 'Disapproved';
  }
}

// ── Widget interne : chip du header ─────────────────────
class _HeaderChip extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final VoidCallback? onTap;

  const _HeaderChip({
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      // Réduire la hauteur du chip tout en laissant suffisamment d'espace.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: chip,
      ),
    );
  }
}