import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_evaluation_report_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/evaluation_report_controller.dart';

/// Bottom sheet listing the groups/boutiques the connected user may select.
/// Only what the controller loaded from the backend is ever shown.
class EvaluationBoutiquePicker extends StatefulWidget {
  const EvaluationBoutiquePicker({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EvaluationBoutiquePicker(),
    );
  }

  @override
  State<EvaluationBoutiquePicker> createState() =>
      _EvaluationBoutiquePickerState();
}

class _EvaluationBoutiquePickerState extends State<EvaluationBoutiquePicker> {
  final EvaluationReportController _controller =
      Get.find<EvaluationReportController>();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expanded = <int>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    // A single group is opened straight away, there is nothing to browse.
    if (_controller.groups.length == 1) {
      _expanded.add(_controller.groups.first.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String? value) =>
      value != null && value.toLowerCase().contains(_query);

  String _groupTitle(AppLocalizations l10n, ReportBoutiqueGroupDto group) =>
      group.id == EvaluationReportController.ungroupedGroupId
          ? l10n.vmEvalReportOtherStores
          : group.name;

  /// Groups matching the search on their own name/code or through a boutique.
  List<ReportBoutiqueGroupDto> _visibleGroups(AppLocalizations l10n) {
    if (_query.isEmpty) return _controller.groups.toList();
    return _controller.groups.where((g) {
      return _matches(_groupTitle(l10n, g)) ||
          _matches(g.code) ||
          g.boutiques.any((b) => _matches(b.libelle) || _matches(b.code));
    }).toList();
  }

  /// When searching, narrow to matching boutiques unless the group itself matched.
  List<ReportBoutiqueOptionDto> _visibleBoutiques(
    AppLocalizations l10n,
    ReportBoutiqueGroupDto group,
  ) {
    if (_query.isEmpty) return group.boutiques;
    if (_matches(_groupTitle(l10n, group)) || _matches(group.code)) {
      return group.boutiques;
    }
    return group.boutiques
        .where((b) => _matches(b.libelle) || _matches(b.code))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFB8D9F5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.vmEvalReportSelectStores,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2D5E),
                      ),
                    ),
                  ),
                  Obx(() {
                    final all = _controller.allBoutiquesSelected;
                    return TextButton(
                      onPressed: _controller.groups.isEmpty
                          ? null
                          : _controller.toggleAllBoutiques,
                      child: Text(
                        all
                            ? l10n.vmEvalReportDeselectAll
                            : l10n.vmEvalReportSelectAll,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.vmEvalReportSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF0F6FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                final groups = _visibleGroups(l10n);
                if (groups.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.vmEvalReportNoMatch,
                      style: const TextStyle(color: Color(0xFF7BACD8)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: groups.length,
                  // Items are built lazily, outside the outer Obx's build, so each
                  // one observes the selection itself.
                  itemBuilder: (context, index) =>
                      Obx(() => _buildGroup(l10n, groups[index])),
                );
              }),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5FAA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Obx(() => Text(
                          '${l10n.vmEvalReportDone} (${_controller.selectedBoutiqueIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(AppLocalizations l10n, ReportBoutiqueGroupDto group) {
    final boutiques = _visibleBoutiques(l10n, group);
    // While searching, matches are shown without making the user open each group.
    final isOpen = _query.isNotEmpty || _expanded.contains(group.id);
    final selected = _controller.selectedCountInGroup(group);
    final fully = _controller.isGroupFullySelected(group);

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            if (!_expanded.remove(group.id)) _expanded.add(group.id);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: fully ? true : (selected > 0 ? null : false),
                  activeColor: const Color(0xFF1E5FAA),
                  onChanged: (_) => _controller.toggleGroup(group),
                ),
                Expanded(
                  child: Text(
                    _groupTitle(l10n, group),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F2D5E),
                    ),
                  ),
                ),
                Text(
                  '$selected/${group.boutiques.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7BACD8),
                  ),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF7BACD8),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        if (isOpen)
          ...boutiques.map(
            (b) => InkWell(
              onTap: () => _controller.toggleBoutique(b.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Checkbox(
                      value: _controller.selectedBoutiqueIds.contains(b.id),
                      activeColor: const Color(0xFF1E5FAA),
                      onChanged: (_) => _controller.toggleBoutique(b.id),
                    ),
                    Expanded(
                      child: Text(
                        b.code.isEmpty ? b.libelle : '${b.libelle} · ${b.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B3F72),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Divider(height: 1, color: Color(0xFFE3EEFA)),
      ],
    );
  }
}
