import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/site_selector.dart';

import '../../controllers/campaign_controller.dart';
import 'execution_screen.dart';
import 'widgets/campaign_card.dart';
import 'widgets/guideline_handler.dart';


class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final ScrollController _scrollController = ScrollController();
  late final CampaignController controller;

  @override
  void initState() {
    super.initState();
    // On initialise le controller ici — Get le garde en mémoire
    controller = Get.put(CampaignController(), permanent: false);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Déclenche le chargement de la page suivante quand on atteint le bas
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (controller.hasNextPage.value &&
          !controller.isLoading.value &&
          !controller.isLoadingMore.value) {
        controller.loadMoreCampaigns();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Reload boutiques every time the screen is built (covers fresh login after logout)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoadingBoutiques.value) {
        controller.boutiques.clear();
        controller.loadBoutiques();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salutation + nom utilisateur + avatar
                    FutureBuilder<String?>(
                      future: const FlutterSecureStorage().read(key: 'currentName'),
                      builder: (context, snapshot) {
                        String displayName = l10n.vmDefaultResponsibleName;
                        String initials = 'AM';

                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                          final rawName = snapshot.data!.trim();
                          displayName = rawName;
                          final parts = rawName.split(' ');
                          if (parts.length == 1) {
                            initials = parts.first.substring(0, 1).toUpperCase();
                          } else {
                            initials = (parts.first.substring(0, 1) +
                                    parts.last.substring(0, 1))
                                .toUpperCase();
                          }
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.vmGreetingHello,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7BACD8),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F2D5E),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Refresh button
                                Obx(() {
                                  final isLoading = controller.isLoading.value;
                                  final unread = controller.totalUnreadComments.value;
                                  return GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () => controller.loadCampaigns(),
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 200),
                                      opacity: isLoading ? 0.5 : 1.0,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            margin: const EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF3FD),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFB8D9F5),
                                              ),
                                            ),
                                            child: isLoading
                                                ? const Center(
                                                    child: SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Color(0xFF1E5FAA),
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.refresh_rounded,
                                                    color: Color(0xFF1E5FAA),
                                                    size: 20,
                                                  ),
                                          ),
                                          if (unread > 0)
                                            Positioned(
                                              top: -2,
                                              right: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 2,
                                                ),
                                                constraints:
                                                    const BoxConstraints(minWidth: 16),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFE74C3C),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  unread > 99 ? '99+' : '$unread',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                                // Avatar
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4A9EDD), Color(0xFF2563B0)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563B0).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Sélecteur de boutique
                    const SiteSelector(),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Contenu selon l'état ─────────────────────
            Obx(() {
              // Aucune boutique sélectionnée
              if (controller.selectedSite.value == null) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.store_outlined,
                    title: l10n.vmSelectBoutiqueTitle,
                    subtitle: l10n.vmSelectBoutiqueSubtitle,
                  ),
                );
              }

              // Chargement en cours
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E5FAA),
                    ),
                  ),
                );
              }

              // Erreur
              if (controller.errorMessage.isNotEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.vmLoadCampaignsErrorTitle,
                    subtitle: l10n.vmErrorLoadingCampaigns(
                      controller.errorMessage.value,
                    ),
                    isError: true,
                  ),
                );
              }

              final visibleCampaigns = controller.visibleCampaigns;

              // Aucune campagne pour ce site
              if (visibleCampaigns.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.campaign_outlined,
                    title: l10n.vmNoActiveCampaignTitle,
                    subtitle: l10n.vmNoActiveCampaignSubtitle,
                  ),
                );
              }

              // ── Liste des campagnes ────────────────────
              final showTrailingLoader = controller.isLoadingMore.value;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < visibleCampaigns.length) {
                        final campaign = visibleCampaigns[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CampaignCard(
                            campaign: campaign,
                            pendingLocalPhotosCount: controller
                                .pendingLocalPhotosCountForCampaign(
                              campaign.campaignId,
                            ),
                            pendingLocalZonesCount: controller
                                .pendingLocalZonesCountForCampaign(
                              campaign.campaignId,
                            ),
                            pendingLocalPhotosByZone: controller
                                .pendingLocalPhotosByZoneForCampaign(
                              campaign.campaignId,
                            ),
                            onEnter: () async {
                              final selectedSite = controller.selectedSite.value;
                              if (selectedSite == null) {
                                return;
                              }
                              await Get.to(
                                () => ExecutionScreen(
                                  campaign: campaign,
                                  siteId: campaign.siteId > 0
                                      ? campaign.siteId
                                      : selectedSite.id,
                                ),
                                transition: Transition.rightToLeft,
                              );
                              await controller.loadCampaigns();
                              await controller.refreshPendingLocalPhotosForLoadedCampaigns();
                            },
                            onGuideline: () {
                              GuidelineHandler.openGuideline(
                                context,
                                campaign,
                              );
                            },
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 6),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF1E5FAA),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount:
                        visibleCampaigns.length + (showTrailingLoader ? 1 : 0),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Widget : état vide / erreur ──────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: isError
                ? const Color(0xFFE74C3C).withOpacity(0.4)
                : const Color(0xFF7BACD8).withOpacity(0.5),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B3F72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF7BACD8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}