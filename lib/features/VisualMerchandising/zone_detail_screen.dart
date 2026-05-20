import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_execution_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/execution_controller.dart';
import 'package:supervisormobile/features/VisualMerchandising/vm_l10n_helpers.dart';



class ZoneDetailScreen extends StatelessWidget {
  final ZoneStatDto zone;
  final VmCampaignDto campaign;

  const ZoneDetailScreen({
    super.key,
    required this.zone,
    required this.campaign,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Get.find() récupère le controller déjà créé dans ExecutionScreen
    // On n'en crée pas un nouveau !
    final controller = Get.find<ExecutionController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(controller, l10n),
            // _buildGuidelineRef(l10n),
            _buildDisapprovalBanner(controller),
            _buildInstructions(context, l10n),
            _buildPhotoGrid(controller, l10n),
            _buildActionBar(controller, l10n),
          ],
        ),
      ),
    );
  }

  // ── 1. Header de la zone ────────────────────────────
  Widget _buildHeader(ExecutionController controller, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF2563B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Top : retour + options
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
                      l10n.vmZonesBackLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Emoji + Nom + Libellé + statut
          Obx(() {
            final currentZone = _resolveCurrentZone(controller);
            final localCount = (controller.zonePhotos[currentZone.zoneId] ?? const <String>[]).length;
            final hasLocalPending =
                localCount > 0 && !currentZone.isApproved;
            final statusColor = _zoneStatusColor(currentZone, hasLocalPending);
            final statusLabel = _zoneStatusLabel(l10n, currentZone, hasLocalPending);

            return Row(
              children: [
                Text(
                  _emojiForCode(currentZone.zoneCode),
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentZone.zoneName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentZone.zoneCode,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 8),

          // Photo counter only
          Obx(() {
            final currentZone = _resolveCurrentZone(controller);
            final localPhotos = controller.zonePhotos[currentZone.zoneId] ?? const <String>[];
            final remotePhotos =
                controller.remotePhotosByZone[currentZone.zoneId] ?? const <VmExecutionPhotoDto>[];
            final backendCount =
                remotePhotos.length >= currentZone.imagesCount
                    ? remotePhotos.length
                    : currentZone.imagesCount;
            final total = backendCount + localPhotos.length;
            final isComplete = currentZone.isApproved ||
                currentZone.isDisapproved ||
                currentZone.isSubmitted;

            return Text(
              vmPhotosLabelWithCheck(l10n, total, isComplete),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 2. Référence guideline ──────────────────────────
  Widget _buildGuidelineRef(AppLocalizations l10n) {
    if (!campaign.containsGuideline) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // TODO: ouvrir la page PDF correspondante
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF5D98A), width: 1.5),
        ),
        child: Row(
          children: [
            const Text('📐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.vmConsultGuidelineForZone,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A6000),
                    ),
                  ),
                  Text(
                    l10n.vmSeeVisualGuidelines,
                    style: const TextStyle(fontSize: 10, color: Color(0xFFB8860B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC89400), size: 18),
          ],
        ),
      ),
    );
  }

  // ── 2b. Bannière de refus ───────────────────────────
  Widget _buildDisapprovalBanner(ExecutionController controller) {
    return Obx(() {
      final currentZone = _resolveCurrentZone(controller);
      if (!currentZone.isDisapproved) return const SizedBox.shrink();

      final issueText = controller.zoneIssues[zone.zoneId];

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECE9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF3A9A0), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFE74C3C),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Zone refusée',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Issue message (if present)
            if (issueText != null && issueText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF3A9A0).withOpacity(0.6)),
                ),
                child: Text(
                  issueText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7B1010),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  'Aucun commentaire de refus fourni.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── 3. Consignes ────────────────────────────────────
  Widget _buildInstructions(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
          iconColor: const Color(0xFF1B3F72),
          collapsedIconColor: const Color(0xFF1B3F72),
          title: Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                l10n.vmPhotoShootInstructions,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B3F72),
                ),
              ),
            ],
          ),
          children: [
            // On génère les consignes selon le type de zone
            ..._instructionsForZone(zone.zoneCode, l10n).map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 5, height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A9EDD),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4A6D96),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Grille de photos ─────────────────────────────
  Widget _buildPhotoGrid(
    ExecutionController controller,
    AppLocalizations l10n,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final localPhotos = controller.zonePhotos[zone.zoneId] ?? const <String>[];
            final remotePhotos =
                controller.remotePhotosByZone[zone.zoneId] ?? const <VmExecutionPhotoDto>[];
            final totalExisting = remotePhotos.length >= zone.imagesCount
                ? remotePhotos.length
                : zone.imagesCount;
            final totalPhotos = totalExisting + localPhotos.length;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(
                l10n.vmPhotosAddedTitle(totalPhotos),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7BACD8),
                  letterSpacing: 0.8,
                ),
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              final currentZone = _resolveCurrentZone(controller);
              final editable = controller.isZoneEditable(currentZone);
              final localPhotos = controller.zonePhotos[zone.zoneId] ?? const <String>[];
              final remotePhotos =
                  controller.remotePhotosByZone[zone.zoneId] ?? const <VmExecutionPhotoDto>[];
              final existingCount = remotePhotos.length >= zone.imagesCount
                  ? remotePhotos.length
                  : zone.imagesCount;

              // Cas : aucune photo du tout
              if (existingCount == 0 && localPhotos.isEmpty) {
                return _buildEmptyPhotoState(l10n);
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                // Total = photos existantes (backend) + photos locales
                itemCount: existingCount + localPhotos.length + 1,
                itemBuilder: (context, index) {
                  // Photos existantes du backend (pas de chemin local)
                  if (index < existingCount) {
                    final maybeUrl =
                        index < remotePhotos.length ? remotePhotos[index].url : null;
                    final photoId =
                        index < remotePhotos.length ? remotePhotos[index].photoId : 0;
                    return Obx(() {
                      final marked =
                          !controller.isRemotePhotoKept(zone.zoneId, photoId);
                      return _ExistingPhotoTile(
                        l10n: l10n,
                        number: index + 1,
                        zoneCode: zone.zoneCode,
                        imageUrl: maybeUrl,
                        photoId: photoId,
                        zoneId: zone.zoneId,
                        isMarkedForDeletion: marked,
                        onDelete: editable
                            ? () {
                                if (!controller.tryToggleRemotePhotoKeep(
                                  zone.zoneId,
                                  photoId,
                                )) {
                                  _showMinPhotoRequiredSnack(l10n);
                                }
                              }
                            : null,
                      );
                    });
                  }

                  // Photos locales ajoutées dans cette session
                  final localIndex = index - existingCount;
                  if (localIndex < localPhotos.length) {
                    return _LocalPhotoTile(
                      path: localPhotos[localIndex],
                      number: index + 1,
                      showDelete: editable,
                      onDelete: () {
                        if (!editable) return;
                        if (!controller.tryRemoveLocalPhoto(
                          zone.zoneId,
                          localIndex,
                        )) {
                          _showMinPhotoRequiredSnack(l10n);
                        }
                      },
                    );
                  }

                  // Bouton "Ajouter"
                  return _AddPhotoTile(
                    l10n: l10n,
                    enabled: editable,
                    onCameraPressed: () =>
                        controller.pickFromCamera(zone.zoneId),
                    onGalleryPressed: () =>
                        controller.pickFromGallery(zone.zoneId),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── 5. Barre d'actions en bas ───────────────────────
  Widget _buildActionBar(
    ExecutionController controller,
    AppLocalizations l10n,
  ) {
    return Obx(() {
      final currentZone = _resolveCurrentZone(controller);
      final editable = controller.isZoneEditable(currentZone);
      final photoCount =
          controller.effectivePhotoCountForZone(currentZone.zoneId);
      final canValidate = editable && photoCount >= 1;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8F1FB))),
        ),
        child: Row(
          children: [
            // Bouton caméra
            _SourceButton(
              icon: Icons.camera_alt_outlined,
              label: l10n.vmCamera,
              onTap: editable ? () => controller.pickFromCamera(zone.zoneId) : null,
            ),
            const SizedBox(width: 10),

            // Bouton galerie
            _SourceButton(
              icon: Icons.photo_library_outlined,
              label: l10n.vmGallery,
              onTap: editable ? () => controller.pickFromGallery(zone.zoneId) : null,
            ),
            const SizedBox(width: 10),

            // Bouton valider
            Expanded(
              child: ElevatedButton(
                onPressed: canValidate
                    ? () => _submitZoneAndGoBack(controller, l10n)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canValidate
                      ? const Color(0xFF1E5FAA)
                      : const Color(0xFFB0C8E0),
                  disabledBackgroundColor: const Color(0xFFB0C8E0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: canValidate ? 4 : 0,
                ),
                child: Obx(() {
                  final isSubmitting = controller.isUploading.value;
                  return isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          !editable
                              ? l10n.vmCampaignCompleted
                              : canValidate
                                  ? l10n.vmValidateZone
                                  : l10n.vmAddPhotosHint,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── État vide ────────────────────────────────────────
  Widget _buildEmptyPhotoState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 36,
              color: Color(0xFF4A9EDD),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.vmNoPhotosAdded,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B3F72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.vmEmptyPhotosHint,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7BACD8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Zone Submission ──────────────────────────────────
  void _showMinPhotoRequiredSnack(AppLocalizations l10n) {
    Get.snackbar(
      l10n.error,
      l10n.vmAtLeastOnePhotoRequired,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }

  Future<void> _submitZoneAndGoBack(
    ExecutionController controller,
    AppLocalizations l10n,
  ) async {
    final currentZone = _resolveCurrentZone(controller);
    if (!controller.isZoneEditable(currentZone)) return;

    final newLocalPhotoPaths = controller.photosForZone(zone.zoneId);
    final keptRemotePhotoIds = controller.getKeptRemotePhotoIds(zone.zoneId);

    if (controller.effectivePhotoCountForZone(zone.zoneId) < 1) {
      _showMinPhotoRequiredSnack(l10n);
      return;
    }

    controller.isUploading.value = true;
    try {
      final response = await controller.submitZoneWithDelta(
        zoneId: zone.zoneId,
        zoneCode: zone.zoneCode,
        keepPhotoIds: keptRemotePhotoIds,
        newLocalPhotoPaths: newLocalPhotoPaths,
      );

      if (!response.success) {
        Get.snackbar(
          l10n.error,
          response.message ?? 'Failed to submit zone',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      controller.removeAllPhotosForZone(zone.zoneId);
      controller.clearRemovedRemotePhotos(zone.zoneId);
      final siteId = controller.getCurrentSiteId();
      if (siteId != null) {
        await controller.loadExecution(
          campaignId: campaign.campaignId,
          siteId: siteId,
        );
      }

      Get.snackbar(
        'Success',
        response.message ?? 'Zone submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      Get.snackbar(
        l10n.error,
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      controller.isUploading.value = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────
  List<String> _instructionsForZone(String code, AppLocalizations l10n) {
    final c = code.toUpperCase();
    if (c.startsWith('VP') || c.startsWith('VL')) {
      return [
        l10n.vmInstructionVp1,
        l10n.vmInstructionVp2,
        l10n.vmInstructionVp3,
      ];
    }
    if (c.startsWith('WD')) {
      return [
        l10n.vmInstructionWd1,
        l10n.vmInstructionWd2,
        l10n.vmInstructionWd3,
      ];
    }
    if (c.startsWith('ZC')) {
      return [
        l10n.vmInstructionZc1,
        l10n.vmInstructionZc2,
        l10n.vmInstructionZc3,
      ];
    }
    return [
      l10n.vmInstructionDef1,
      l10n.vmInstructionDef2,
      l10n.vmInstructionDef3,
    ];
  }

  String _emojiForCode(String code) {
    final c = code.toUpperCase();
    if (c.startsWith('VP') || c.startsWith('VL')) return '🪟';
    if (c.startsWith('WD')) return '🧱';
    if (c.startsWith('EA')) return '🪑';
    if (c.startsWith('PE')) return '💡';
    if (c.startsWith('ZC')) return '🛍';
    if (c.startsWith('ZS')) return '📦';
    if (c.startsWith('ZR')) return '🚪';
    if (c.startsWith('ZE')) return '🎪';
    return '📍';
  }

  ZoneStatDto _resolveCurrentZone(ExecutionController controller) {
    for (final current in controller.zones) {
      if (current.zoneId == zone.zoneId) return current;
    }
    return zone;
  }

  Color _zoneStatusColor(ZoneStatDto currentZone, bool hasLocalPending) {
    if (currentZone.isDisapproved) return const Color(0xFFE74C3C);
    if (currentZone.isApproved) return const Color(0xFF27AE73);
    if (currentZone.isSubmitted || hasLocalPending) return const Color(0xFFF5A623);
    return Colors.white.withOpacity(0.85);
  }

  String _zoneStatusLabel(
    AppLocalizations l10n,
    ZoneStatDto currentZone,
    bool hasLocalPending,
  ) {
    final isFrench = l10n.localeName.toLowerCase().startsWith('fr');
    if (currentZone.isDisapproved) {
      return isFrench ? 'Desapprouvee' : 'Disapproved';
    }
    if (currentZone.isApproved) {
      return isFrench ? 'Approuvee' : 'Approved';
    }
    if (currentZone.isSubmitted || hasLocalPending) {
      return isFrench ? 'Soumise' : 'Submitted';
    }
    return l10n.vmZoneStatusTodo;
  }
}

// ── Tuile : photo existante (venant du backend) ─────────
class _ExistingPhotoTile extends StatelessWidget {
  final AppLocalizations l10n;
  final int number;
  final String zoneCode;
  final String? imageUrl;
  final int photoId;
  final int zoneId;
  final VoidCallback? onDelete;
  final bool isMarkedForDeletion;

  const _ExistingPhotoTile({
    required this.l10n,
    required this.number,
    required this.zoneCode,
    required this.photoId,
    required this.zoneId,
    this.imageUrl,
    this.onDelete,
    this.isMarkedForDeletion = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: isMarkedForDeletion
            ? const Color(0xFFFFECE9)
            : const Color(0xFFDBEEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMarkedForDeletion
              ? const Color(0xFFF3A9A0)
              : const Color(0xFF4A9EDD).withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Get.to(
                  () => _FullScreenImageViewer.network(imageUrl: imageUrl!),
                  transition: Transition.fadeIn,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    opacity: isMarkedForDeletion ? 0.5 : 1.0,
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  ),
                ),
              ),
            )
          else
            Opacity(
              opacity: isMarkedForDeletion ? 0.5 : 1.0,
              child: _placeholder(),
            ),
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E5FAA).withOpacity(0.85),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '#$number',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isMarkedForDeletion
                      ? const Color(0xFFE74C3C).withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isMarkedForDeletion ? Icons.close : Icons.delete_outline,
                  size: 14,
                  color: isMarkedForDeletion
                      ? Colors.white
                      : const Color(0xFFE74C3C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image, size: 36, color: Color(0xFF4A9EDD)),
          const SizedBox(height: 6),
          Text(
            l10n.vmPhotoNumberLabel(number),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E5FAA),
            ),
          ),
          Text(
            l10n.vmPhotoSent,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7BACD8)),
          ),
        ],
      ),
    );
  }
}

// ── Tuile : photo locale (prise dans cette session) ─────
class _LocalPhotoTile extends StatelessWidget {
  final String path;
  final int number;
  final bool showDelete;
  final VoidCallback onDelete;

  const _LocalPhotoTile({
    required this.path,
    required this.number,
    this.showDelete = true,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => _FullScreenImageViewer.file(imagePath: path),
        transition: Transition.fadeIn,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vraie photo depuis le fichier local
            Image.file(
              File(path),
              fit: BoxFit.cover,
            ),

          // Dégradé en bas
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Numéro en haut à gauche
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E5FAA).withOpacity(0.85),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '#$number',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          if (showDelete)
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;

  const _FullScreenImageViewer.network({required this.imageUrl}) : imagePath = null;
  const _FullScreenImageViewer.file({required this.imagePath}) : imageUrl = null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 56,
                  ),
                )
              : Image.file(
                  File(imagePath!),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

// ── Tuile : bouton ajouter ───────────────────────────────
class _AddPhotoTile extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final bool enabled;

  const _AddPhotoTile({
    required this.l10n,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      // La campagne terminée doit empêcher d'ajouter des photos.
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFB8D4ED),
              width: 2,
              // ignore: deprecated_member_use
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8ECFA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: Color(0xFF4A9EDD),
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.vmAddPhoto,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A9EDD),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniSourceBtn(
                    icon: Icons.camera_alt_outlined,
                    onTap: enabled ? onCameraPressed : null,
                  ),
                  const SizedBox(width: 8),
                  _MiniSourceBtn(
                    icon: Icons.photo_library_outlined,
                    onTap: enabled ? onGalleryPressed : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSourceBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _MiniSourceBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && enabled;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.7,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FD),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled
                ? const Color(0xFF1E5FAA)
                : Colors.white.withOpacity(0.55),
          ),
        ),
      ),
    );
  }
}

// ── Bouton source (caméra / galerie) dans le footer ─────
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? const Color(0xFFB8D9F5) : const Color(0xFFD2E6FA),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? const Color(0xFF1E5FAA) : Colors.white.withOpacity(0.55),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? const Color(0xFF1E5FAA)
                    : Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}