import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supervisormobile/features/VisualMerchandising/evaluation_report_controller.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/evaluation_boutique_picker.dart';
import 'package:supervisormobile/features/VisualMerchandising/widgets/evaluation_grid_sheet.dart';

/// Mobile counterpart of the web "evaluation grid report": pick grid models,
/// stores and a period, then browse the criteria × week grids per store.
class EvaluationReportScreen extends StatefulWidget {
  const EvaluationReportScreen({super.key});

  @override
  State<EvaluationReportScreen> createState() => _EvaluationReportScreenState();
}

class _EvaluationReportScreenState extends State<EvaluationReportScreen> {
  late final EvaluationReportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(EvaluationReportController());
  }

  @override
  void dispose() {
    Get.delete<EvaluationReportController>();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 3),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: DateUtils.dateOnly(controller.startDate.value),
        end: DateUtils.dateOnly(controller.endDate.value),
      ),
    );
    if (picked != null) controller.setDateRange(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F6FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2D5E)),
        title: Text(
          l10n.vmEvalReportTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F2D5E),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            _buildFilters(context, l10n),
            const SizedBox(height: 16),
            _buildResults(context, l10n),
          ],
        ),
      ),
    );
  }

  // ── Filters ──────────────────────────────────────────────

  Widget _buildFilters(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8D9F5)),
      ),
      child: Obx(() {
        if (controller.isLoadingFilters.value) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E5FAA)),
            ),
          );
        }

        if (controller.filtersError.isNotEmpty) {
          return _MessageBlock(
            icon: Icons.error_outline,
            title: l10n.vmEvalReportErrorTitle,
            subtitle: controller.filtersError.value,
            isError: true,
            actionLabel: l10n.vmEvalReportRetry,
            onAction: controller.loadFilters,
          );
        }

        final boutiqueCount = controller.selectedBoutiqueIds.length;
        final storesLabel = boutiqueCount == 0
            ? l10n.vmEvalReportSelectStores
            : boutiqueCount == 1
                ? l10n.vmEvalReportOneStoreSelected
                : l10n.vmEvalReportStoresSelected(boutiqueCount);
        final locale = Localizations.localeOf(context).toString();
        final dateFmt = DateFormat.yMMMd(locale);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(l10n.vmEvalReportGridModels),
            _buildTemplateChips(l10n),
            const SizedBox(height: 16),
            _SectionLabel(l10n.vmEvalReportStores),
            _FieldButton(
              icon: Icons.store_outlined,
              label: storesLabel,
              highlighted: boutiqueCount > 0,
              onTap: () => EvaluationBoutiquePicker.show(context),
            ),
            const SizedBox(height: 16),
            _SectionLabel(l10n.vmEvalReportPeriod),
            _FieldButton(
              icon: Icons.date_range_rounded,
              label:
                  '${dateFmt.format(controller.startDate.value)} → ${dateFmt.format(controller.endDate.value)}',
              highlighted: true,
              onTap: _pickDateRange,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.canSearch ? controller.loadReport : null,
                icon: controller.isLoadingReport.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bar_chart_rounded, size: 20),
                label: Text(
                  l10n.vmEvalReportApply,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5FAA),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8D9F5),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTemplateChips(AppLocalizations l10n) {
    final templates = controller.templates;
    if (templates.isEmpty) {
      return Text(
        l10n.vmEvalReportNoGridModels,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF7BACD8)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          label: Text(l10n.vmEvalReportAllModels),
          selected: controller.allTemplatesSelected,
          onSelected: (_) => controller.toggleAllTemplates(),
          showCheckmark: true,
          selectedColor: const Color(0xFFD6E8FA),
          checkmarkColor: const Color(0xFF1E5FAA),
        ),
        for (final template in templates)
          FilterChip(
            label: Text(template.name),
            selected: controller.selectedTemplateIds.contains(template.id),
            onSelected: (_) => controller.toggleTemplate(template.id),
            showCheckmark: true,
            selectedColor: const Color(0xFFD6E8FA),
            checkmarkColor: const Color(0xFF1E5FAA),
          ),
      ],
    );
  }

  // ── Results ──────────────────────────────────────────────

  Widget _buildResults(BuildContext context, AppLocalizations l10n) {
    return Obx(() {
      if (controller.isLoadingFilters.value || controller.filtersError.isNotEmpty) {
        return const SizedBox.shrink();
      }

      if (controller.isLoadingReport.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF1E5FAA)),
          ),
        );
      }

      if (!controller.hasSearched.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: _MessageBlock(
            icon: Icons.filter_alt_outlined,
            title: l10n.vmEvalReportInitialTitle,
            subtitle: l10n.vmEvalReportInitialSubtitle,
          ),
        );
      }

      if (controller.reportError.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: _MessageBlock(
            icon: Icons.error_outline,
            title: l10n.vmEvalReportErrorTitle,
            subtitle: controller.reportError.value,
            isError: true,
            actionLabel: l10n.vmEvalReportRetry,
            onAction: controller.loadReport,
          ),
        );
      }

      final templates = controller.report
          .where((t) => t.boutiques.isNotEmpty)
          .toList();
      if (templates.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: _MessageBlock(
            icon: Icons.bar_chart_rounded,
            title: l10n.vmEvalReportNoResultsTitle,
            subtitle: l10n.vmEvalReportNoResultsSubtitle,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final template in templates) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
              child: Text(
                '${l10n.vmEvalReportGrid} · ${template.templateName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B3F72),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            for (final boutique in template.boutiques)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: EvaluationGridSheet(
                  template: template,
                  boutique: boutique,
                ),
              ),
          ],
        ],
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7BACD8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FieldButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _FieldButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB8D9F5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1E5FAA)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: highlighted
                      ? const Color(0xFF0F2D5E)
                      : const Color(0xFF7BACD8),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7BACD8)),
          ],
        ),
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 52,
            color: isError
                ? const Color(0xFFE74C3C).withOpacity(0.4)
                : const Color(0xFF7BACD8).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B3F72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF7BACD8),
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
