import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_evaluation_report_dto.dart';

const double _criteriaColWidth = 140;
const double _weekColWidth = 54;
const double _rowHeight = 46;
const double _headerHeight = 30;

const Color _ink = Color(0xFF0F2D5E);
const Color _muted = Color(0xFF7BACD8);
const Color _line = Color(0xFFE3EEFA);
const Color _headFill = Color(0xFFEAF3FD);

/// One boutique's evaluation grid for one template: criteria down the side
/// (pinned), weeks across (scrolls horizontally), weekly totals underneath.
class EvaluationGridSheet extends StatelessWidget {
  final EvaluationReportTemplateDto template;
  final EvaluationReportBoutiqueDto boutique;

  const EvaluationGridSheet({
    super.key,
    required this.template,
    required this.boutique,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final months = _monthGroups(boutique.weeks, locale);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB8D9F5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563B0).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.store_outlined, size: 18, color: Color(0xFF1E5FAA)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    boutique.boutiqueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pinned criteria column ──
              SizedBox(
                width: _criteriaColWidth,
                child: Column(
                  children: [
                    _cell(
                      height: _headerHeight * 2,
                      fill: _headFill,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.vmEvalReportCriteria,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    for (final criteria in template.criteria)
                      _criteriaLabel(context, l10n, criteria),
                    _cell(
                      height: _rowHeight,
                      fill: _headFill,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${l10n.vmEvalReportWeeklyTotal}\n(${_fmt(template.totalCoefficient)})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Scrolling weeks ──
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (final month in months)
                            _cell(
                              width: _weekColWidth * month.weekCount,
                              height: _headerHeight,
                              fill: _headFill,
                              child: Text(
                                month.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                          _cell(
                            width: _weekColWidth,
                            height: _headerHeight,
                            fill: _headFill,
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          for (final week in boutique.weeks)
                            _weekHeader(context, l10n, week, locale),
                          _cell(
                            width: _weekColWidth,
                            height: _headerHeight,
                            fill: _headFill,
                            child: Text(
                              l10n.vmEvalReportAverage,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final criteria in template.criteria)
                        Row(
                          children: [
                            for (final week in boutique.weeks)
                              _scoreCell(context, l10n, criteria, week),
                            _cell(
                              width: _weekColWidth,
                              height: _rowHeight,
                              fill: const Color(0xFFF7FAFE),
                              child: Text(
                                _fmtNullable(boutique.criterionAverage(criteria.labelKey)),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          for (final week in boutique.weeks)
                            _totalCell(context, l10n, week),
                          _cell(
                            width: _weekColWidth,
                            height: _rowHeight,
                            fill: _headFill,
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Cells ────────────────────────────────────────────────

  Widget _cell({
    required double height,
    required Widget child,
    double? width,
    Color? fill,
    Alignment alignment = Alignment.center,
    EdgeInsets padding = EdgeInsets.zero,
    VoidCallback? onTap,
  }) {
    final box = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        border: const Border(
          top: BorderSide(color: _line),
          right: BorderSide(color: _line),
        ),
      ),
      child: child,
    );
    return onTap == null
        ? box
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: box,
          );
  }

  Widget _criteriaLabel(
    BuildContext context,
    AppLocalizations l10n,
    EvaluationReportCriteriaDto criteria,
  ) {
    final hasDetails = (criteria.description ?? '').trim().isNotEmpty;
    return _cell(
      height: _rowHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      fill: criteria.isActive ? null : const Color(0xFFF7F7F7),
      onTap: () => _showInfo(
        context,
        title: criteria.label,
        lines: [
          '${l10n.vmEvalReportWeight}: ${_fmt(criteria.coefficient)}',
          if (!criteria.isActive) l10n.vmEvalReportRetiredCriterion,
          if (hasDetails) criteria.description!.trim(),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              criteria.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: criteria.isActive ? _ink : _muted,
              ),
            ),
          ),
          if (!criteria.isActive)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.archive_outlined, size: 12, color: _muted),
            ),
        ],
      ),
    );
  }

  Widget _weekHeader(
    BuildContext context,
    AppLocalizations l10n,
    EvaluationReportWeekDto week,
    String locale,
  ) {
    final label = week.weekNumber != null ? 'S${week.weekNumber}' : week.campaignLibelle;
    return _cell(
      width: _weekColWidth,
      height: _headerHeight,
      fill: _headFill,
      onTap: () => _showInfo(
        context,
        title: week.campaignLibelle.isEmpty ? label : week.campaignLibelle,
        lines: [
          _period(week, locale),
          if (week.isMerged) l10n.vmEvalReportMergedWeek(week.mergedEvaluationCount),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
          if (week.isMerged)
            const Padding(
              padding: EdgeInsets.only(left: 2),
              child: Icon(Icons.layers_outlined, size: 11, color: _muted),
            ),
        ],
      ),
    );
  }

  Widget _scoreCell(
    BuildContext context,
    AppLocalizations l10n,
    EvaluationReportCriteriaDto criteria,
    EvaluationReportWeekDto week,
  ) {
    final cell = week.cellFor(criteria.labelKey);
    // Criterion absent from that week's grid version: blank, not a dash.
    if (cell == null || cell.notApplicable) {
      return _cell(
        width: _weekColWidth,
        height: _rowHeight,
        fill: const Color(0xFFF7F7F7),
        child: const SizedBox.shrink(),
      );
    }

    final comment = (cell.comment ?? '').trim();
    return _cell(
      width: _weekColWidth,
      height: _rowHeight,
      onTap: comment.isEmpty
          ? null
          : () => _showInfo(
                context,
                title: criteria.label,
                subtitle: week.weekNumber != null ? 'S${week.weekNumber}' : week.campaignLibelle,
                lines: [comment],
              ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cell.score?.toString() ?? '—',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          if (comment.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 11, color: Color(0xFF1E5FAA)),
            ),
        ],
      ),
    );
  }

  Widget _totalCell(
    BuildContext context,
    AppLocalizations l10n,
    EvaluationReportWeekDto week,
  ) {
    final total = week.averageScore;
    final colors = _totalColors(week);
    return _cell(
      width: _weekColWidth,
      height: _rowHeight,
      fill: colors.background,
      onTap: total == null
          ? null
          : () => _showInfo(
                context,
                title: l10n.vmEvalReportWeeklyTotal,
                subtitle: week.weekNumber != null ? 'S${week.weekNumber}' : week.campaignLibelle,
                lines: [_totalSummary(week)],
              ),
      child: Text(
        total == null ? '—' : total.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: colors.foreground,
        ),
      ),
    );
  }

  // ── Colouring / text ─────────────────────────────────────

  /// The band colour is a saturated foreground hue, so it tints the cell and is
  /// darkened for the figure — used raw as a fill it would swallow the number.
  /// Grids with no bands fall back to the share of the version's maximum.
  ({Color? background, Color foreground}) _totalColors(EvaluationReportWeekDto week) {
    const empty = (background: null as Color?, foreground: _muted);
    if (week.averageScore == null) return empty;

    final base = week.level != null ? parseReportColor(week.level!.color) : null;
    if (base != null) {
      return (
        background: Color.lerp(base, Colors.white, 0.8),
        foreground: Color.lerp(base, Colors.black, 0.45)!,
      );
    }

    final ratio = week.ratio;
    if (ratio == null) return empty;
    final fallback = ratio >= 0.8
        ? const Color(0xFF2E9E5B)
        : ratio >= 0.5
            ? const Color(0xFFE0A21B)
            : const Color(0xFFD64545);
    return (
      background: Color.lerp(fallback, Colors.white, 0.8),
      foreground: Color.lerp(fallback, Colors.black, 0.45)!,
    );
  }

  /// "43 / 60 (72%) · v2 · Good (41–50)"
  String _totalSummary(EvaluationReportWeekDto week) {
    final total = week.averageScore!;
    final parts = <String>[
      week.maxScore > 0
          ? '${_fmt(total)} / ${_fmt(week.maxScore)} (${((week.ratio ?? 0) * 100).round()}%)'
          : _fmt(total),
      'v${week.versionNumber}',
    ];
    final level = week.level;
    if (level != null && level.label.isNotEmpty) {
      parts.add('${level.label} (${_fmt(level.minValue)}–${_fmt(level.maxValue)})');
    }
    return parts.join(' · ');
  }

  String _period(EvaluationReportWeekDto week, String locale) {
    final fmt = DateFormat.yMd(locale);
    final start = week.campaignStartDate;
    final end = week.campaignEndDate;
    if (start == null || end == null) return '';
    return '${fmt.format(start.toLocal())} → ${fmt.format(end.toLocal())}';
  }

  /// Consecutive weeks under their calendar month. Keyed on the week's own Monday:
  /// grouping on the campaign start would file every week of a long campaign
  /// under the month it began in.
  List<({String label, int weekCount})> _monthGroups(
    List<EvaluationReportWeekDto> weeks,
    String locale,
  ) {
    final fmt = DateFormat.yMMMM(locale);
    final groups = <({String label, int weekCount})>[];
    for (final week in weeks) {
      final label = fmt.format(week.weekStartDate);
      if (groups.isNotEmpty && groups.last.label == label) {
        groups[groups.length - 1] = (label: label, weekCount: groups.last.weekCount + 1);
      } else {
        groups.add((label: label, weekCount: 1));
      }
    }
    return groups;
  }

  String _fmt(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }

  String _fmtNullable(double? value) => value == null ? '—' : value.toStringAsFixed(1);

  void _showInfo(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<String> lines,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
              ],
              const SizedBox(height: 10),
              for (final line in lines.where((l) => l.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Color(0xFF1B3F72),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
