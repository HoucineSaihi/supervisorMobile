import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import '../../../controllers/campaign_controller.dart';
import '../../calendar/models/boutiqueModel.dart';

class SiteSelector extends StatelessWidget {
  const SiteSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Get.find() récupère le controller qu'on a créé plus tôt
    final controller = Get.find<CampaignController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label au dessus
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.vmSelectBoutiqueSectionLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7BACD8),
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Résumé du nombre de boutiques chargées
        Obx(() {
          final count = controller.boutiques.length;
          final isLoading = controller.isLoadingBoutiques.value;

          String text;
          if (isLoading) {
            text = l10n.vmLoadingBoutiques;
          } else if (count == 0) {
            text = l10n.vmNoBoutiquesLoaded;
          } else if (count == 1) {
            text = l10n.vmOneBoutiqueAvailable;
          } else {
            text = l10n.vmNbBoutiquesAvailable(count);
          }

          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7BACD8),
              ),
            ),
          );
        }),

        // Liste horizontale des boutiques ou Selector
        Obx(() {
          // Afficher un loader pendant le chargement
          if (controller.isLoadingBoutiques.value) {
            return const SizedBox(
              height: 56,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1E5FAA),
                ),
              ),
            );
          }

          // Afficher un message si aucune boutique
          if (controller.boutiques.isEmpty) {
            return SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  l10n.vmNoBoutiqueAvailable,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7BACD8),
                  ),
                ),
              ),
            );
          }

          // Si plus de 4 boutiques, afficher un selector avec recherche
          if (controller.boutiques.length > 4) {
            return _SearchableSelector(controller: controller, l10n: l10n);
          }

          // Sinon, afficher les pins horizontaux
          return SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: controller.boutiques.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final site = controller.boutiques[index];

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
                      child: Center(
                        child: Text(
                          site.libelle ??
                              site.code ??
                              l10n.vmBoutiqueFallback(site.id),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0F2D5E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          );
        }),
      ],
    );
  }
}

// ── Widget : Selector avec recherche ─────────────────────
class _SearchableSelector extends StatelessWidget {
  final CampaignController controller;
  final AppLocalizations l10n;

  const _SearchableSelector({
    required this.controller,
    required this.l10n,
  });

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _BoutiqueSearchDialog(controller: controller, l10n: l10n);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedSite = controller.selectedSite.value;

      return GestureDetector(
        onTap: () => _showSearchDialog(context),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedSite != null
                  ? const Color(0xFF1E5FAA)
                  : const Color(0xFFE2EEF8),
              width: 1.5,
            ),
            boxShadow: selectedSite != null
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E5FAA).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                Icons.store_outlined,
                size: 20,
                color: selectedSite != null
                    ? const Color(0xFF1E5FAA)
                    : const Color(0xFF7BACD8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedSite != null
                      ? (selectedSite.libelle ??
                          selectedSite.code ??
                          l10n.vmBoutiqueFallback(selectedSite.id))
                      : l10n.vmSelectBoutiquePlaceholder,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selectedSite != null
                        ? const Color(0xFF0F2D5E)
                        : const Color(0xFF7BACD8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.search,
                size: 18,
                color: const Color(0xFF7BACD8),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Dialog : Recherche de boutique ────────────────────────
class _BoutiqueSearchDialog extends StatefulWidget {
  final CampaignController controller;
  final AppLocalizations l10n;

  const _BoutiqueSearchDialog({
    required this.controller,
    required this.l10n,
  });

  @override
  State<_BoutiqueSearchDialog> createState() => _BoutiqueSearchDialogState();
}

class _BoutiqueSearchDialogState extends State<_BoutiqueSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<BoutiqueModel> _filteredBoutiques = [];

  @override
  void initState() {
    super.initState();
    _filteredBoutiques = widget.controller.boutiques;
    _searchController.addListener(_filterBoutiques);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBoutiques);
    _searchController.dispose();
    super.dispose();
  }

  void _filterBoutiques() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBoutiques = widget.controller.boutiques;
      } else {
        _filteredBoutiques = widget.controller.boutiques.where((boutique) {
          final name = (boutique.libelle ??
                  boutique.code ??
                  widget.l10n.vmBoutiqueFallback(boutique.id))
              .toLowerCase();
          final city = (boutique.city ?? '').toLowerCase();
          final code = (boutique.code ?? '').toLowerCase();
          return name.contains(query) ||
              city.contains(query) ||
              code.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B3F72), Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.vmSearchBoutiqueTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.vmSearchBoutiqueHint,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7BACD8)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF7BACD8)),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF0F6FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2EEF8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2EEF8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1E5FAA), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Boutiques list
            Flexible(
              child: _filteredBoutiques.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l10n.vmNoBoutiqueFound,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7BACD8),
                          ),
                        ),
                      ),
                    )
                  : Obx(() {
                      // Re-filter when selected site changes to update checkmarks
                      final selectedId = widget.controller.selectedSite.value?.id;
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredBoutiques.length,
                        itemBuilder: (context, index) {
                          final boutique = _filteredBoutiques[index];
                          final isSelected = selectedId == boutique.id;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E5FAA)
                                    : const Color(0xFFE2EEF8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.store,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF7BACD8),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              boutique.libelle ??
                                  boutique.code ??
                                  l10n.vmBoutiqueFallback(boutique.id),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF1E5FAA)
                                    : const Color(0xFF0F2D5E),
                              ),
                            ),
                            subtitle: boutique.city != null
                                ? Text(
                                    boutique.city!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7BACD8),
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF1E5FAA),
                                  )
                                : null,
                            onTap: () {
                              widget.controller.selectSite(boutique);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}