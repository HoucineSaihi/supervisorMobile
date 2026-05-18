import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_execution_dto.dart';
import 'package:supervisormobile/controllers/campaign_controller.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_submit_dto.dart';
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
  /// Rejection issue text per zone (null when zone is not disapproved or has no message).
  final RxMap<int, String?> zoneIssues = <int, String?>{}.obs;
  final ImagePicker _picker = ImagePicker();
  VmCampaignDto? _campaign;
  int? _loadedCampaignId;
  int? _loadedSiteId;

  /// Updated after submit and kept in sync with [_campaign]; drives [ExecutionScreen] UI.
  final Rx<VmCampaignDto?> liveCampaign = Rx<VmCampaignDto?>(null);

  /// Submission status returned by the executions API.
  final Rx<SubmissionStatus> submissionStatus = SubmissionStatus.unknown.obs;

  /// True when the submission is locked and no further edits are allowed.
  bool get isSubmissionLocked => submissionStatus.value.isLocked;

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
    try {
      await File('debug-64022c.log').writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('ExecutionController._logDebug skipped: $e');
    }
  }
  // #endregion

  Future<void> init(VmCampaignDto campaign, int siteId) async {
    if (_loadedCampaignId == campaign.campaignId && _loadedSiteId == siteId) {
      liveCampaign.value = _campaign;
      return;
    }
    _campaign = campaign;
    liveCampaign.value = campaign;
    _loadedCampaignId = campaign.campaignId;
    _loadedSiteId = siteId;
    zonePhotos.clear();
    remotePhotosByZone.clear();
    zones.assignAll(campaign.allZones);
    for (final zone in campaign.allZones) {
      zonePhotos[zone.zoneId] = <String>[];
    }
    await _loadPendingLocalPhotos();
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

  int? getCurrentSiteId() => _loadedSiteId;

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

  bool isZoneValidated(ZoneStatDto zone) => zone.isApproved;

  bool hasLocalPending(ZoneStatDto zone) =>
      localPhotoCount(zone.zoneId) > 0 && !zone.isApproved && !zone.isDisapproved;

  bool isZoneComplete(ZoneStatDto zone) =>
      zone.isApproved ||
      zone.isDisapproved ||
      zone.isSubmitted ||
      localPhotoCount(zone.zoneId) > 0;

  double get globalProgress {
    if (zones.isEmpty) return 0.0;
    final completed = zones.where(isZoneComplete).length;
    return completed / zones.length;
  }

  /// True when the campaign is already submitted (drives button disabled state).
  bool get isCampaignSubmitted {
    final s = liveCampaign.value?.status ?? _campaign?.status;
    return s == CampaignStatus.submitted ||
        s == CampaignStatus.approved ||
        s == CampaignStatus.disapproved;
  }

  bool get canSubmit {
    if (isCampaignSubmitted) return false;
    if (isSubmissionLocked) return false;
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
      _logDebug(
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
      submissionStatus.value = result.submissionStatus;
      zones.assignAll(result.zoneStats);
      remotePhotosByZone.clear();
      zoneIssues.clear();
      for (final zone in result.zones) {
        remotePhotosByZone[zone.zoneId] = zone.allPhotos;
        zonePhotos.putIfAbsent(zone.zoneId, () => <String>[]);
        final issues = zone.rejectionIssues;
        if (issues != null) zoneIssues[zone.zoneId] = issues;
      }

      // #region agent log
      _logDebug(
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
      _logDebug(
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
    bool keepShooting = true;
    int addedCount = 0;
    while (keepShooting) {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) break;
      zonePhotos[zoneId] = [...photosForZone(zoneId), picked.path];
      zonePhotos.refresh();
      addedCount++;

      final ctx = Get.context;
      if (ctx == null) break;
      keepShooting = await showDialog<bool>(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Another photo?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: const Text('Do you want to take another photo for this zone?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Done'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5FAA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Take another'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (addedCount > 0) await _savePendingLocalPhotos();
    // #region agent log
    _logDebug(
      runId: 'pre-fix',
      hypothesisId: 'H4',
      location: 'execution_controller.dart:pickFromCamera',
      message: 'Photos added from camera',
      data: {
        'zoneId': zoneId,
        'addedCount': addedCount,
        'localPhotoCount': localPhotoCount(zoneId),
      },
    );
    // #endregion
  }

  Future<void> pickFromGallery(int zoneId) async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    zonePhotos[zoneId] = [...photosForZone(zoneId), ...picked.map((x) => x.path)];
    zonePhotos.refresh();
    await _savePendingLocalPhotos();
    // #region agent log
    _logDebug(
      runId: 'pre-fix',
      hypothesisId: 'H4',
      location: 'execution_controller.dart:pickFromGallery',
      message: 'Photos added from gallery',
      data: {
        'zoneId': zoneId,
        'addedCount': picked.length,
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
    _savePendingLocalPhotos();
  }

  void removeAllPhotosForZone(int zoneId) {
    zonePhotos[zoneId] = <String>[];
    zonePhotos.refresh();
    _savePendingLocalPhotos();
  }

  final RxMap<int, Set<int>> _removedRemotePhotoIds = <int, Set<int>>{}.obs;

  bool isRemotePhotoKept(int zoneId, int photoId) {
    final removedIds = _removedRemotePhotoIds[zoneId] ?? <int>{};
    return !removedIds.contains(photoId);
  }

  void toggleRemotePhotoKeep(int zoneId, int photoId) {
    final removedIds = _removedRemotePhotoIds[zoneId] ?? <int>{};
    if (removedIds.contains(photoId)) {
      removedIds.remove(photoId);
    } else {
      removedIds.add(photoId);
    }
    _removedRemotePhotoIds[zoneId] = removedIds;
    _removedRemotePhotoIds.refresh();
  }

  List<int> getKeptRemotePhotoIds(int zoneId) {
    final remotePhotos = remotePhotosByZone[zoneId] ?? <VmExecutionPhotoDto>[];
    final removedIds = _removedRemotePhotoIds[zoneId] ?? <int>{};
    return remotePhotos
        .where((p) => !removedIds.contains(p.photoId))
        .map((p) => p.photoId)
        .toList();
  }

  void clearRemovedRemotePhotos(int zoneId) {
    _removedRemotePhotoIds.remove(zoneId);
  }

  Future<VmZoneSubmitResponseDto> submitZoneWithDelta({
    required int zoneId,
    required String zoneCode,
    required List<int> keepPhotoIds,
    required List<String> newLocalPhotoPaths,
  }) async {
    final campaign = _campaign;
    final siteId = _loadedSiteId;
    if (campaign == null || siteId == null) {
      throw Exception('Campaign or site not loaded');
    }

    return _vmService.submitZoneExecution(
      campaignId: campaign.campaignId,
      siteId: siteId,
      zoneId: zoneId,
      zoneCode: zoneCode,
      keepPhotoIds: keepPhotoIds,
      newPhotoPaths: newLocalPhotoPaths,
      platform: _platformName(),
      appVersion: '1.0.0',
    );
  }

  Future<void> submitCampaign() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final l10n = AppLocalizations.of(ctx)!;

    final campaign = _campaign;
    final siteId = _loadedSiteId;
    if (campaign == null || siteId == null) return;

    if (zones.isEmpty) {
      Get.snackbar(
        l10n.error,
        l10n.vmNoZonesToSubmit,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    isUploading.value = true;
    try {
      final result = await _vmService.finalizeSiteExecution(
        campaignId: campaign.campaignId,
        siteId: siteId,
        platform: _platformName(),
        appVersion: '1.0.0',
      );

      await loadExecution(campaignId: campaign.campaignId, siteId: siteId);
      await _refreshCampaignListIfAvailable();

      if (result.success) {
        Get.snackbar(
          l10n.vmSubmitSuccessTitle,
          result.message ?? 'Campaign submitted successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    } on VmSubmitApiException catch (e) {
      final incompleteIds = e.response?.incompleteZoneIds ?? const <int>[];
      final detail = incompleteIds.isNotEmpty
          ? ' (zones: ${incompleteIds.join(', ')})'
          : '';
      Get.snackbar(
        l10n.error,
        '${e.message}$detail',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
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
      isUploading.value = false;
    }
  }

  Future<void> _refreshCampaignListIfAvailable() async {
    if (!Get.isRegistered<CampaignController>()) return;
    final cc = Get.find<CampaignController>();
    await cc.loadCampaigns();
    final id = _campaign?.campaignId;
    if (id == null) return;
    for (final c in cc.campaigns) {
      if (c.campaignId == id) {
        _campaign = c;
        liveCampaign.value = c;
        break;
      }
    }
  }

  String _buildSubmitErrorMessage(
    AppLocalizations l10n,
    VmSubmitApiException error,
  ) {
    if (error.response != null && error.response!.errors.isNotEmpty) {
      final mapped = error.response!.errors.map((e) {
        final zoneSuffix = e.zoneId != null
            ? l10n.vmErrorZoneIdSuffix(e.zoneId!)
            : '';
        switch (e.code) {
          case 'ZONE_NOT_ASSIGNED':
            return l10n.vmErrorZoneNotAssigned(zoneSuffix);
          case 'NO_PHOTOS':
            return l10n.vmErrorNoPhotos(zoneSuffix);
          case 'INVALID_IMAGE_FORMAT':
            return l10n.vmErrorInvalidImageFormat(zoneSuffix);
          case 'INVALID_BASE64':
            return l10n.vmErrorInvalidBase64(zoneSuffix);
          default:
            return l10n.vmErrorValidation(zoneSuffix);
        }
      }).join(' | ');
      return '${error.message}. $mapped';
    }

    if (error.statusCode == 404) {
      return l10n.vmErrorCampaignNotFound404;
    }
    if (error.statusCode == 500) {
      return l10n.vmErrorServer500Retry;
    }
    return error.message;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String? _pendingPhotosPrefsKey() {
    final campaignId = _loadedCampaignId;
    final siteId = _loadedSiteId;
    if (campaignId == null || siteId == null) return null;
    return 'vm_pending_photos_${campaignId}_$siteId';
  }

  Future<void> _loadPendingLocalPhotos() async {
    final key = _pendingPhotosPrefsKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    bool hasPrunedInvalidPath = false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      decoded.forEach((zoneIdRaw, pathsDynamic) {
        final zoneId = int.tryParse(zoneIdRaw);
        if (zoneId == null || pathsDynamic is! List) return;
        final sanitized = <String>[];
        for (final pathDynamic in pathsDynamic) {
          if (pathDynamic is! String || pathDynamic.isEmpty) continue;
          if (File(pathDynamic).existsSync()) {
            sanitized.add(pathDynamic);
          } else {
            hasPrunedInvalidPath = true;
          }
        }
        if (sanitized.isNotEmpty) {
          zonePhotos[zoneId] = sanitized;
        } else {
          zonePhotos.putIfAbsent(zoneId, () => <String>[]);
        }
      });

      zonePhotos.refresh();
      if (hasPrunedInvalidPath) {
        await _savePendingLocalPhotos();
      }
    } catch (_) {
      await prefs.remove(key);
    }
  }

  Future<void> _savePendingLocalPhotos() async {
    final key = _pendingPhotosPrefsKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, List<String>>{};

    zonePhotos.forEach((zoneId, paths) {
      if (paths.isEmpty) return;
      final existing = paths.where((p) => p.isNotEmpty && File(p).existsSync()).toList();
      if (existing.isNotEmpty) {
        payload[zoneId.toString()] = existing;
      }
    });

    if (payload.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(payload));
  }

  Future<void> _clearPendingLocalPhotos() async {
    final key = _pendingPhotosPrefsKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
