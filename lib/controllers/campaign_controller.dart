import 'package:get/get.dart';

import '../features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import '../features/VisualMerchandising/dtos/vm_campaign_fake_data.dart';


class CampaignController extends GetxController {

  // ── State (toutes les variables .obs se mettent à jour l'UI auto) ──

  // La boutique actuellement sélectionnée (null = aucune)
  final Rx<FakeSite?> selectedSite = Rx<FakeSite?>(null);

  // La liste des campagnes chargées pour ce site
  final RxList<VmCampaignDto> campaigns = <VmCampaignDto>[].obs;

  // Est-ce qu'on est en train de charger ?
  final RxBool isLoading = false.obs;

  // Message d'erreur (vide = pas d'erreur)
  final RxString errorMessage = ''.obs;

  // ── Sélectionner une boutique ──────────────────────────
  void selectSite(FakeSite site) {
    selectedSite.value = site;
    loadCampaigns(); // charge les campagnes dès qu'on choisit un site
  }

  // ── Charger les campagnes ──────────────────────────────
  // Pour l'instant on utilise les fake data.
  // Plus tard on remplacera par un vrai appel API.
  Future<void> loadCampaigns() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Simule un délai réseau de 800ms
      await Future.delayed(const Duration(milliseconds: 800));

      // TODO: remplacer par → await campaignService.getBySites([selectedSite.value!.id]);
      campaigns.assignAll(fakeCampaigns);

    } catch (e) {
      errorMessage.value = 'Erreur lors du chargement des campagnes.';
    } finally {
      isLoading.value = false;
    }
  }
}