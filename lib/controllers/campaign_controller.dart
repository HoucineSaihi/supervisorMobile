import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/services/vm_service.dart';

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
  final RxBool isLoadingMore = false.obs;

  // Est-ce qu'on est en train de charger les boutiques ?
  final RxBool isLoadingBoutiques = false.obs;

  // Message d'erreur (vide = pas d'erreur)
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxMap<int, int> pendingLocalPhotosByCampaign = <int, int>{}.obs;
  final RxMap<int, int> pendingLocalZonesByCampaign = <int, int>{}.obs;
  final RxMap<int, Map<int, int>> pendingLocalPhotosByZoneByCampaign =
      <int, Map<int, int>>{}.obs;

  /// Global unread comment badge (from kpis or sum of campaigns).
  final RxInt totalUnreadComments = 0.obs;

  void _resetPagination() {
    currentPage.value = 1;
    totalPages.value = 1;
    totalCount.value = 0;
    hasNextPage.value = false;
    pendingLocalPhotosByCampaign.clear();
    pendingLocalZonesByCampaign.clear();
    pendingLocalPhotosByZoneByCampaign.clear();
    totalUnreadComments.value = 0;
  }

  void _recomputeTotalUnreadComments() {
    totalUnreadComments.value =
        campaigns.fold<int>(0, (sum, c) => sum + c.unreadCommentCount);
  }

  void _applyUnreadCountsFromPage(VmCampaignsPageDto page, {required bool append}) {
    if (!append && page.kpis != null) {
      totalUnreadComments.value = page.kpis!.totalUnreadComments;
      return;
    }
    _recomputeTotalUnreadComments();
  }

  void markCampaignCommentsRead(int campaignId) {
    if (campaignId <= 0) return;
    final index = campaigns.indexWhere((c) => c.campaignId == campaignId);
    if (index < 0) return;
    final previous = campaigns[index].unreadCommentCount;
    if (previous <= 0) return;
    campaigns[index] = campaigns[index].copyWith(unreadCommentCount: 0);
    totalUnreadComments.value =
        (totalUnreadComments.value - previous).clamp(0, 1 << 30);
  }

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
      errorMessage.value = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
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
    campaigns.clear();
    errorMessage.value = '';
    _resetPagination();
    loadCampaigns(); // charge les campagnes dès qu'on choisit un site
  }

  // ── Charger les campagnes ──────────────────────────────
  Future<void> loadCampaigns() async {
    if (selectedSite.value == null) {
      if (kDebugMode) {
        print('⚠️ CampaignController.loadCampaigns() — no selectedSite, abort');
      }
      campaigns.clear();
      _resetPagination();
      return;
    }
    if (isLoading.value || isLoadingMore.value) return;

    if (kDebugMode) {
      print('📡 CampaignController.loadCampaigns() — start for siteId=${selectedSite.value!.id}');
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _vmService.getCampaignsBySites(
        [selectedSite.value!.id],
        pageNumber: 1,
      );
      campaigns.assignAll(response.data);
      _applyUnreadCountsFromPage(response, append: false);
      currentPage.value = response.pagination.pageNumber;
      totalPages.value = response.pagination.totalPages;
      totalCount.value = response.pagination.totalCount;
      hasNextPage.value = response.pagination.hasNextPage;
      await refreshPendingLocalPhotosForLoadedCampaigns();
      if (kDebugMode) {
        print(
          '✅ CampaignController.loadCampaigns() — loaded ${response.data.length} campaigns '
          '(page ${response.pagination.pageNumber}/${response.pagination.totalPages})',
        );
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      campaigns.clear();
      _resetPagination();
      print('❌ Error loading campaigns: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreCampaigns() async {
    final selected = selectedSite.value;
    if (selected == null) return;
    if (!hasNextPage.value || isLoading.value || isLoadingMore.value) return;

    final nextPage = currentPage.value + 1;
    isLoadingMore.value = true;
    try {
      final response = await _vmService.getCampaignsBySites(
        [selected.id],
        pageNumber: nextPage,
      );
      campaigns.addAll(response.data);
      _applyUnreadCountsFromPage(response, append: true);
      currentPage.value = response.pagination.pageNumber;
      totalPages.value = response.pagination.totalPages;
      totalCount.value = response.pagination.totalCount;
      hasNextPage.value = response.pagination.hasNextPage;
      await refreshPendingLocalPhotosForLoadedCampaigns();
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    } finally {
      isLoadingMore.value = false;
    }
  }

  int pendingLocalPhotosCountForCampaign(int campaignId) {
    return pendingLocalPhotosByCampaign[campaignId] ?? 0;
  }

  int pendingLocalZonesCountForCampaign(int campaignId) {
    return pendingLocalZonesByCampaign[campaignId] ?? 0;
  }

  Map<int, int> pendingLocalPhotosByZoneForCampaign(int campaignId) {
    return pendingLocalPhotosByZoneByCampaign[campaignId] ?? const <int, int>{};
  }

  Future<void> refreshPendingLocalPhotosForLoadedCampaigns() async {
    final selected = selectedSite.value;
    if (selected == null) {
      pendingLocalPhotosByCampaign.clear();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final photoSnapshot = <int, int>{};
    final zoneSnapshot = <int, int>{};
    final zonePhotoSnapshot = <int, Map<int, int>>{};

    for (final campaign in campaigns) {
      final key = 'vm_pending_photos_${campaign.campaignId}_${selected.id}';
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        var count = 0;
        var zonesWithLocal = 0;
        final byZone = <int, int>{};
        decoded.forEach((zoneIdRaw, listDynamic) {
          if (listDynamic is! List) return;
          final zoneId = int.tryParse(zoneIdRaw);
          if (zoneId == null) return;
          var zoneHasValidLocal = false;
          var zonePhotoCount = 0;
          for (final pathDynamic in listDynamic) {
            if (pathDynamic is! String || pathDynamic.isEmpty) continue;
            if (File(pathDynamic).existsSync()) {
              count++;
              zoneHasValidLocal = true;
              zonePhotoCount++;
            }
          }
          if (zoneHasValidLocal) zonesWithLocal++;
          if (zonePhotoCount > 0) byZone[zoneId] = zonePhotoCount;
        });
        if (count > 0) {
          photoSnapshot[campaign.campaignId] = count;
        }
        if (zonesWithLocal > 0) {
          zoneSnapshot[campaign.campaignId] = zonesWithLocal;
        }
        if (byZone.isNotEmpty) {
          zonePhotoSnapshot[campaign.campaignId] = byZone;
        }
      } catch (_) {
        await prefs.remove(key);
      }
    }

    pendingLocalPhotosByCampaign
      ..clear()
      ..addAll(photoSnapshot);
    pendingLocalPhotosByCampaign.refresh();
    pendingLocalZonesByCampaign
      ..clear()
      ..addAll(zoneSnapshot);
    pendingLocalZonesByCampaign.refresh();
    pendingLocalPhotosByZoneByCampaign
      ..clear()
      ..addAll(zonePhotoSnapshot);
    pendingLocalPhotosByZoneByCampaign.refresh();
  }
}