import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/execution_controller.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/zone_row.dart';
import 'package:supervisormobile/features/VisualMerchandising/zone_detail_screen.dart';


class ExecutionScreen extends StatelessWidget {
  final VmCampaignDto campaign;
  final int siteId;

  const ExecutionScreen({super.key, required this.campaign, required this.siteId});

  ExecutionStatsDto? get _stats => campaign.firstGuideline;

  @override
  Widget build(BuildContext context) {
    // On crée le controller ET on lui passe la campagne
    final controller = Get.put(ExecutionController());
    controller.init(campaign, siteId);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(controller),
            _buildGuidelineBanner(),
            _buildZoneList(controller),
            _buildSubmitBar(controller),
          ],
        ),
      ),
    );
  }

  // ── 1. Header avec progression globale ─────────────
  Widget _buildHeader(ExecutionController controller) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Bouton retour
          GestureDetector(
            onTap: () => Get.back(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.chevron_left, color: Colors.white70, size: 20),
                Text(
                  'Campagnes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF7EFFA0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'En cours',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Titre campagne
          Text(
            campaign.libelle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          // Stats : 3 chips
          Obx(() {
            final zones = controller.zones;
            final completed = zones
                .where((z) => controller.isZoneComplete(z))
                .length;
            final pct = (controller.globalProgress * 100).toInt();

            return Row(
              children: [
                _HeaderChip(
                  value: '$pct%',
                  label: 'Complétion',
                ),
                const SizedBox(width: 10),
                _HeaderChip(
                  value: '$completed/${zones.length}',
                  label: 'Zones',
                ),
                const SizedBox(width: 10),
                _HeaderChip(
                  value: campaign.isOverdue
                      ? 'Dépassé'
                      : '${campaign.daysRemaining}j',
                  label: 'Restants',
                  valueColor: campaign.isOverdue
                      ? const Color(0xFFFF8A80)
                      : const Color(0xFFFFD27A),
                ),
              ],
            );
          }),

          const SizedBox(height: 14),

          // Barre de progression globale
          Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Avancement global',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${controller.totalBackendPhotos + controller.zonePhotos.values.fold(0, (s, l) => s + l.length)} photos',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: controller.globalProgress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ── 2. Bannière guideline ───────────────────────────
  Widget _buildGuidelineBanner() {
    if (!campaign.containsGuideline) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // TODO: ouvrir le PDF
        Get.snackbar(
          '📄 Guideline',
          _stats?.guidelineName ?? 'Guideline',
          snackPosition: SnackPosition.BOTTOM,
        );
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
                  const Text(
                    'Guideline VM',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3F72),
                    ),
                  ),
                  Text(
                    _stats?.guidelineName ?? 'Guideline',
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
  Widget _buildZoneList(ExecutionController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Text(
              'ZONES À COMPLÉTER',
              style: TextStyle(
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
              final zones = controller.zones;
              if (zones.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune zone trouvée.',
                    style: TextStyle(
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
                      child: const Text(
                        'Données live indisponibles: affichage des stats de campagne.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFC87700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        return ZoneRow(
                          zone: zone,
                          isZoneValidated: controller.isZoneValidated(zone),
                          hasLocalPending: controller.hasLocalPending(zone),
                          totalPhotoCount: controller.totalPhotoCount(zone),
                          onTap: () {
                            Get.to(
                              () => ZoneDetailScreen(
                                zone: zone,
                                campaign: campaign,
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

  // ── 4. Bouton soumettre (sticky en bas) ────────────
  Widget _buildSubmitBar(ExecutionController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8F1FB))),
      ),
      child: Column(
        children: [
          // Bouton soumettre
          Obx(() {
            final canSubmit = controller.canSubmit;
            final isUploading = controller.isUploading.value;

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit && !isUploading
                    ? () => controller.submitCampaign()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit
                      ? const Color(0xFF27AE73)
                      : const Color(0xFFB0C8E0),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB0C8E0),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: canSubmit ? 4 : 0,
                  shadowColor: const Color(0xFF27AE73).withOpacity(0.3),
                ),
                child: isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  canSubmit
                      ? '✉️  Soumettre la campagne'
                      : 'Complétez toutes les zones',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),

          // Hint sous le bouton
          Obx(() {
            if (controller.canSubmit) return const SizedBox.shrink();
            final zones = controller.zones;
            final remaining = zones
                .where((z) => !controller.isZoneComplete(z))
                .length;
            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                '$remaining zone${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8AB2D4),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Widget interne : chip du header ─────────────────────
class _HeaderChip extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _HeaderChip({
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}