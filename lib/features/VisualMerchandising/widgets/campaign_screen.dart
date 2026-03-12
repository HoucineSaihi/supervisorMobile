import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/site_selector.dart';

import '../../../controllers/campaign_controller.dart';
import 'campaign_card.dart';
import 'guideline_handler.dart';


class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On initialise le controller ici — Get le garde en mémoire
    final controller = Get.put(CampaignController(), permanent: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salutation + avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'BONJOUR, RESPONSABLE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7BACD8),
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Campagnes VM',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F2D5E),
                              ),
                            ),
                          ],
                        ),
                        // Avatar initiales
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
                          child: const Center(
                            child: Text(
                              'AM',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sélecteur de boutique
                    const SiteSelector(),

                    const SizedBox(height: 20),
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
                    title: 'Sélectionnez une boutique',
                    subtitle:
                    'Choisissez une boutique ci-dessus\npour voir ses campagnes.',
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
                    title: 'Erreur de chargement',
                    subtitle: controller.errorMessage.value,
                    isError: true,
                  ),
                );
              }

              // Aucune campagne
              if (controller.campaigns.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'Aucune campagne active',
                    subtitle: 'Cette boutique n\'a pas\nde campagne en cours.',
                  ),
                );
              }

              // ── Liste des campagnes ────────────────────
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CampaignCard(
                        campaign: controller.campaigns[index],
                        onEnter: () {
                          // TODO: naviguer vers ZoneScreen
                          // Get.to(() => ZoneScreen(campaign: controller.campaigns[index]));
                        },
                        onGuideline: () {
                          GuidelineHandler.openGuideline(context, controller.campaigns[index]);
                        },
                      ),
                    ),
                    childCount: controller.campaigns.length,
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