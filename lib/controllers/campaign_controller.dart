import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import '../features/VisualMerchandising/services/vm_service.dart';
import '../features/calendar/models/boutiqueModel.dart';

class CampaignController extends GetxController {
  final VmService _vmService = VmService();

  // ── State (toutes les variables .obs se mettent à jour l'UI auto) ──

  // La liste des boutiques disponibles
  final RxList<BoutiqueModel> boutiques = <BoutiqueModel>[].obs;

  // La boutique actuellement sélectionnée (null = aucune)
  final Rx<BoutiqueModel?> selectedSite = Rx<BoutiqueModel?>(null);

  // La liste des campagnes chargées pour ce site
  final RxList<VmCampaignDto> campaigns = <VmCampaignDto>[].obs;

  // Est-ce qu'on est en train de charger ?
  final RxBool isLoading = false.obs;

  // Est-ce qu'on est en train de charger les boutiques ?
  final RxBool isLoadingBoutiques = false.obs;

  // Message d'erreur (vide = pas d'erreur)
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    if (kDebugMode) {
      print('📲 CampaignController.onInit() called');
    }
    super.onInit();
    // Charger les boutiques au démarrage
    loadBoutiques();
  }

  // ── Charger les boutiques ──────────────────────────────
  Future<void> loadBoutiques() async {
    // Éviter les appels concurrents
    if (isLoadingBoutiques.value) {
      if (kDebugMode) {
        print('⏳ CampaignController.loadBoutiques() — already loading, skip');
      }
      return;
    }

    if (kDebugMode) {
      print('📡 CampaignController.loadBoutiques() — start');
    }
    isLoadingBoutiques.value = true;
    errorMessage.value = '';

    try {
      // Le backend utilise l'ID de l'utilisateur depuis le token
      // On passe un tableau vide car le paramètre n'est pas utilisé
      final boutiquesList = await _vmService.getBoutiquesByUserIds([]);
      boutiques.assignAll(boutiquesList);
      if (kDebugMode) {
        print('✅ CampaignController.loadBoutiques() — loaded ${boutiquesList.length} boutiques');
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors du chargement des boutiques: ${e.toString()}';
      print('❌ Error loading boutiques: $e');
    } finally {
      isLoadingBoutiques.value = false;
    }
  }

  // ── Sélectionner une boutique ──────────────────────────
  void selectSite(BoutiqueModel site) {
    if (kDebugMode) {
      print('🛍 CampaignController.selectSite() — id=${site.id}, name=${site.libelle ?? site.code}');
    }
    selectedSite.value = site;
    loadCampaigns(); // charge les campagnes dès qu'on choisit un site
  }

  // ── Charger les campagnes ──────────────────────────────
  Future<void> loadCampaigns() async {
    if (selectedSite.value == null) {
      if (kDebugMode) {
        print('⚠️ CampaignController.loadCampaigns() — no selectedSite, abort');
      }
      campaigns.clear();
      return;
    }

    if (kDebugMode) {
      print('📡 CampaignController.loadCampaigns() — start for siteId=${selectedSite.value!.id}');
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final campaignsList = await _vmService.getCampaignsBySites([selectedSite.value!.id]);
      campaigns.assignAll(campaignsList);
      if (kDebugMode) {
        print('✅ CampaignController.loadCampaigns() — loaded ${campaignsList.length} campaigns');
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors du chargement des campagnes: ${e.toString()}';
      campaigns.clear();
      print('❌ Error loading campaigns: $e');
    } finally {
      isLoading.value = false;
    }
  }
}