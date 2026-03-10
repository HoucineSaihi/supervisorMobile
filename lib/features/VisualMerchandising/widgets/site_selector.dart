import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/campaign_controller.dart';
import '../dtos/vm_campaign_fake_data.dart';

class SiteSelector extends StatelessWidget {
  const SiteSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.find() récupère le controller qu'on a créé plus tôt
    final controller = Get.find<CampaignController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label au dessus
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'SÉLECTIONNER UNE BOUTIQUE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7BACD8),
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Liste horizontale des boutiques
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: fakeSites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final site = fakeSites[index];

              // Obx() écoute selectedSite et redessine quand ça change
              return Obx(() {
                final isSelected = controller.selectedSite.value?.id == site.id;

                return GestureDetector(
                  onTap: () => controller.selectSite(site),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E5FAA)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E5FAA)
                            : const Color(0xFFE2EEF8),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(
                        color: const Color(0xFF1E5FAA).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0F2D5E),
                          ),
                        ),
                        Text(
                          site.city,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFF7BACD8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}