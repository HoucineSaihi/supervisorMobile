import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_evaluation_report_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/services/vm_service.dart';

class EvaluationReportController extends GetxController {
  /// Id of the synthetic group holding boutiques the user can reach but that
  /// belong to no group (e.g. a single-boutique manager).
  static const int ungroupedGroupId = -1;

  final VmService _vmService = VmService();

  // ── Filter sources ──
  final RxList<EvaluationGridTemplateOptionDto> templates =
      <EvaluationGridTemplateOptionDto>[].obs;
  final RxList<ReportBoutiqueGroupDto> groups = <ReportBoutiqueGroupDto>[].obs;

  // ── Selection ──
  final RxSet<int> selectedTemplateIds = <int>{}.obs;
  final RxSet<int> selectedBoutiqueIds = <int>{}.obs;
  final Rx<DateTime> startDate =
      DateTime.now().subtract(const Duration(days: 28)).obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  // ── State ──
  final RxBool isLoadingFilters = false.obs;
  final RxBool isLoadingReport = false.obs;
  final RxBool hasSearched = false.obs;
  final RxString filtersError = ''.obs;
  final RxString reportError = ''.obs;
  final RxList<EvaluationReportTemplateDto> report =
      <EvaluationReportTemplateDto>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFilters();
  }

  // ── Filters ──────────────────────────────────────────────

  Future<void> loadFilters() async {
    if (isLoadingFilters.value) return;
    isLoadingFilters.value = true;
    filtersError.value = '';

    try {
      final results = await Future.wait([
        _vmService.getEvaluationGridTemplates(),
        _loadSelectableGroups(),
      ]);

      final loadedTemplates = results[0] as List<EvaluationGridTemplateOptionDto>;
      final loadedGroups = results[1] as List<ReportBoutiqueGroupDto>;

      templates.assignAll(loadedTemplates);
      groups.assignAll(loadedGroups);

      // Grid models start fully selected; boutiques are an explicit choice.
      selectedTemplateIds
        ..clear()
        ..addAll(loadedTemplates.map((t) => t.id));

      // Drop any previous boutique choice the user can no longer select.
      final selectable = allBoutiqueIds;
      selectedBoutiqueIds.removeWhere((id) => !selectable.contains(id));
    } catch (e) {
      filtersError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingFilters.value = false;
    }
  }

  /// The boutiques the connected user may pick, grouped. Comes from the same
  /// endpoint as the web report (scoped by role on the backend); boutiques the
  /// mobile campaign list already exposes but no group contains are added under
  /// an "ungrouped" entry so no role is left with an empty picker.
  Future<List<ReportBoutiqueGroupDto>> _loadSelectableGroups() async {
    final eligible = await _vmService.getEligibleGroups();

    try {
      final known = eligible.expand((g) => g.boutiques).map((b) => b.id).toSet();
      final mine = await _vmService.getBoutiquesByUserIds([]);
      final ungrouped = mine
          .where((b) => !known.contains(b.id))
          .map((b) => ReportBoutiqueOptionDto(
                id: b.id,
                code: b.code ?? '',
                libelle: b.libelle ?? '',
              ))
          .toList();

      if (ungrouped.isNotEmpty) {
        return [
          ...eligible,
          ReportBoutiqueGroupDto(
            id: ungroupedGroupId,
            name: '',
            code: '',
            boutiques: ungrouped,
          ),
        ];
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ EvaluationReportController: ungrouped boutiques skipped: $e');
    }

    return eligible;
  }

  // ── Templates ────────────────────────────────────────────

  bool get allTemplatesSelected =>
      templates.isNotEmpty && templates.every((t) => selectedTemplateIds.contains(t.id));

  void toggleTemplate(int id) {
    if (!selectedTemplateIds.remove(id)) selectedTemplateIds.add(id);
  }

  void toggleAllTemplates() {
    if (allTemplatesSelected) {
      selectedTemplateIds.clear();
    } else {
      selectedTemplateIds.assignAll(templates.map((t) => t.id));
    }
  }

  // ── Boutiques ────────────────────────────────────────────

  /// Distinct selectable boutiques (one may appear in several groups).
  Set<int> get allBoutiqueIds =>
      groups.expand((g) => g.boutiques).map((b) => b.id).toSet();

  bool get allBoutiquesSelected {
    final all = allBoutiqueIds;
    return all.isNotEmpty && all.every(selectedBoutiqueIds.contains);
  }

  void toggleBoutique(int id) {
    if (!selectedBoutiqueIds.remove(id)) selectedBoutiqueIds.add(id);
  }

  void toggleAllBoutiques() {
    if (allBoutiquesSelected) {
      selectedBoutiqueIds.clear();
    } else {
      selectedBoutiqueIds.assignAll(allBoutiqueIds);
    }
  }

  bool isGroupFullySelected(ReportBoutiqueGroupDto group) =>
      group.boutiques.isNotEmpty &&
      group.boutiques.every((b) => selectedBoutiqueIds.contains(b.id));

  int selectedCountInGroup(ReportBoutiqueGroupDto group) =>
      group.boutiques.where((b) => selectedBoutiqueIds.contains(b.id)).length;

  void toggleGroup(ReportBoutiqueGroupDto group) {
    final ids = group.boutiques.map((b) => b.id);
    if (isGroupFullySelected(group)) {
      selectedBoutiqueIds.removeAll(ids);
    } else {
      selectedBoutiqueIds.addAll(ids);
    }
  }

  // ── Dates ────────────────────────────────────────────────

  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
  }

  // ── Report ───────────────────────────────────────────────

  bool get canSearch =>
      !isLoadingReport.value &&
      selectedTemplateIds.isNotEmpty &&
      selectedBoutiqueIds.isNotEmpty;

  Future<void> loadReport() async {
    if (!canSearch) return;

    isLoadingReport.value = true;
    hasSearched.value = true;
    reportError.value = '';

    try {
      // Only ever send boutiques the user is allowed to select.
      final selectable = allBoutiqueIds;
      final result = await _vmService.getEvaluationGridReport(
        templateIds: selectedTemplateIds.toList(),
        boutiqueIds: selectedBoutiqueIds.where(selectable.contains).toList(),
        startDate: startDate.value,
        endDate: endDate.value,
      );
      report.assignAll(result);
    } catch (e) {
      report.clear();
      reportError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingReport.value = false;
    }
  }
}
