import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_execution_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/services/vm_service.dart';


class ExecutionController extends GetxController {
  final VmService _vmService = VmService();
  final RxMap<int, List<String>> zonePhotos = <int, List<String>>{}.obs;
  final RxBool isUploading = false.obs;
  final RxBool isLoadingExecution = false.obs;
  final RxString executionError = ''.obs;
  final RxList<ZoneStatDto> zones = <ZoneStatDto>[].obs;
  final RxMap<int, List<VmExecutionPhotoDto>> remotePhotosByZone =
      <int, List<VmExecutionPhotoDto>>{}.obs;
  final ImagePicker _picker = ImagePicker();
  VmCampaignDto? _campaign;
  int? _loadedCampaignId;
  int? _loadedSiteId;

  // #region agent log
  Future<void> _logDebug({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    final payload = <String, dynamic>{
      'sessionId': '64022c',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await File('debug-64022c.log').writeAsString(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }
  // #endregion

  Future<void> init(VmCampaignDto campaign, int siteId) async {
    if (_loadedCampaignId == campaign.campaignId && _loadedSiteId == siteId) {
      return;
    }
    _campaign = campaign;
    _loadedCampaignId = campaign.campaignId;
    _loadedSiteId = siteId;
    zonePhotos.clear();
    remotePhotosByZone.clear();
    zones.assignAll(campaign.allZones);
    for (final zone in campaign.allZones) {
      zonePhotos[zone.zoneId] = <String>[];
    }
    // #region agent log
    _logDebug(
      runId: 'pre-fix',
      hypothesisId: 'H1_H4',
      location: 'execution_controller.dart:init',
      message: 'ExecutionController initialized',
      data: {
        'campaignId': campaign.campaignId,
        'zonesCount': campaign.allZones.length,
        'guidelinesCount': campaign.executionsStats.length,
        'siteId': siteId,
      },
    );
    // #endregion
    await loadExecution(campaignId: campaign.campaignId, siteId: siteId);
  }

  List<String> photosForZone(int zoneId) => zonePhotos[zoneId] ?? <String>[];
  List<VmExecutionPhotoDto> remotePhotosForZone(int zoneId) =>
      remotePhotosByZone[zoneId] ?? <VmExecutionPhotoDto>[];

  int remotePhotoCount(int zoneId) => remotePhotosForZone(zoneId).length;

  int backendPhotoCount(ZoneStatDto zone) {
    final remoteCount = remotePhotoCount(zone.zoneId);
    return remoteCount >= zone.imagesCount ? remoteCount : zone.imagesCount;
  }

  int localPhotoCount(int zoneId) => photosForZone(zoneId).length;

  int totalPhotoCount(ZoneStatDto zone) =>
      backendPhotoCount(zone) + localPhotoCount(zone.zoneId);

  bool isZoneValidated(ZoneStatDto zone) => zone.isFinished;

  bool hasLocalPending(ZoneStatDto zone) =>
      localPhotoCount(zone.zoneId) > 0 && !zone.isFinished;

  bool isZoneComplete(ZoneStatDto zone) =>
      zone.isFinished || localPhotoCount(zone.zoneId) > 0;

  double get globalProgress {
    if (zones.isEmpty) return 0.0;
    final completed = zones.where(isZoneComplete).length;
    return completed / zones.length;
  }

  bool get canSubmit {
    if (zones.isEmpty) return false;
    return zones.every(isZoneComplete);
  }

  int get totalBackendPhotos =>
      zones.fold<int>(0, (sum, zone) => sum + backendPhotoCount(zone));

  Future<void> loadExecution({
    required int campaignId,
    required int siteId,
  }) async {
    final campaign = _campaign;
    if (campaign == null) return;
    isLoadingExecution.value = true;
    executionError.value = '';
    try {
      // #region agent log
      await _logDebug(
        runId: 'pre-fix',
        hypothesisId: 'H3_H4',
        location: 'execution_controller.dart:loadExecution:start',
        message: 'Loading execution from API',
        data: {'campaignId': campaignId, 'siteId': siteId},
      );
      // #endregion

      final result = await _vmService.getCampaignExecutionBySite(
        campaignId: campaignId,
        siteId: siteId,
      );
      zones.assignAll(result.zoneStats);
      remotePhotosByZone.clear();
      for (final zone in result.zones) {
        remotePhotosByZone[zone.zoneId] = zone.allPhotos;
        zonePhotos.putIfAbsent(zone.zoneId, () => <String>[]);
      }

      // #region agent log
      await _logDebug(
        runId: 'pre-fix',
        hypothesisId: 'H3_H4',
        location: 'execution_controller.dart:loadExecution:success',
        message: 'Execution API loaded',
        data: {
          'campaignId': result.campaignId,
          'siteId': result.siteId,
          'zonesCount': result.zones.length,
          'photosCount': result.totalRemoteImages,
        },
      );
      // #endregion
    } catch (e) {
      executionError.value = e.toString();
      zones.assignAll(campaign.allZones);
      // #region agent log
      await _logDebug(
        runId: 'pre-fix',
        hypothesisId: 'H3',
        location: 'execution_controller.dart:loadExecution:fallback',
        message: 'Execution API failed, fallback to campaign stats',
        data: {
          'campaignId': campaignId,
          'siteId': siteId,
          'fallbackZones': campaign.allZones.length,
          'error': executionError.value,
        },
      );
      // #endregion
    } finally {
      isLoadingExecution.value = false;
    }
  }

  Future<void> pickFromCamera(int zoneId) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    zonePhotos[zoneId] = [...photosForZone(zoneId), picked.path];
    zonePhotos.refresh();
    // #region agent log
    _logDebug(
      runId: 'pre-fix',
      hypothesisId: 'H4',
      location: 'execution_controller.dart:pickFromCamera',
      message: 'Photo added from camera',
      data: {
        'zoneId': zoneId,
        'localPhotoCount': localPhotoCount(zoneId),
      },
    );
    // #endregion
  }

  Future<void> pickFromGallery(int zoneId) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    zonePhotos[zoneId] = [...photosForZone(zoneId), picked.path];
    zonePhotos.refresh();
    // #region agent log
    _logDebug(
      runId: 'pre-fix',
      hypothesisId: 'H4',
      location: 'execution_controller.dart:pickFromGallery',
      message: 'Photo added from gallery',
      data: {
        'zoneId': zoneId,
        'localPhotoCount': localPhotoCount(zoneId),
      },
    );
    // #endregion
  }

  void removePhoto(int zoneId, int index) {
    final current = photosForZone(zoneId);
    if (index < 0 || index >= current.length) return;
    final updated = [...current]..removeAt(index);
    zonePhotos[zoneId] = updated;
    zonePhotos.refresh();
  }

  Future<void> submitCampaign() async {
    if (!canSubmit) return;
    isUploading.value = true;
    // #region agent log
    await _logDebug(
      runId: 'pre-fix',
      hypothesisId: 'H5',
      location: 'execution_controller.dart:submitCampaign',
      message: 'Submit tapped',
      data: {
        'canSubmit': canSubmit,
        'globalProgress': globalProgress,
        'zonesWithLocalPhotos': zonePhotos.values.where((v) => v.isNotEmpty).length,
      },
    );
    // #endregion
    isUploading.value = false;
    Get.snackbar(
      'Campagne prête',
      'Soumission locale effectuée.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }
}
