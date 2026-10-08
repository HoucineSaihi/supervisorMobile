import 'package:flutter/material.dart';

/// An evaluation grid model the user can include in the report.
class EvaluationGridTemplateOptionDto {
  final int id;
  final String name;

  const EvaluationGridTemplateOptionDto({required this.id, required this.name});

  factory EvaluationGridTemplateOptionDto.fromJson(Map<String, dynamic> json) {
    return EvaluationGridTemplateOptionDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

class ReportBoutiqueOptionDto {
  final int id;
  final String code;
  final String libelle;

  const ReportBoutiqueOptionDto({
    required this.id,
    required this.code,
    required this.libelle,
  });

  factory ReportBoutiqueOptionDto.fromJson(Map<String, dynamic> json) {
    return ReportBoutiqueOptionDto(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
    );
  }
}

/// A group of boutiques the connected user is allowed to select.
class ReportBoutiqueGroupDto {
  final int id;
  final String name;
  final String code;
  final List<ReportBoutiqueOptionDto> boutiques;

  const ReportBoutiqueGroupDto({
    required this.id,
    required this.name,
    required this.code,
    required this.boutiques,
  });

  factory ReportBoutiqueGroupDto.fromJson(Map<String, dynamic> json) {
    return ReportBoutiqueGroupDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      boutiques: ((json['boutiques'] as List<dynamic>?) ?? const [])
          .map((b) => ReportBoutiqueOptionDto.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EvaluationReportCriteriaDto {
  final String labelKey;
  final String label;
  final String? description;
  final double coefficient;

  /// False when the criterion was dropped from the grid's current version.
  final bool isActive;

  const EvaluationReportCriteriaDto({
    required this.labelKey,
    required this.label,
    required this.description,
    required this.coefficient,
    required this.isActive,
  });

  factory EvaluationReportCriteriaDto.fromJson(Map<String, dynamic> json) {
    return EvaluationReportCriteriaDto(
      labelKey: json['labelKey'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String?,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class EvaluationReportCellDto {
  final String labelKey;
  final int? score;
  final String? comment;

  /// True when the criterion did not exist in the version used that week.
  final bool notApplicable;

  const EvaluationReportCellDto({
    required this.labelKey,
    required this.score,
    required this.comment,
    required this.notApplicable,
  });

  factory EvaluationReportCellDto.fromJson(Map<String, dynamic> json) {
    return EvaluationReportCellDto(
      labelKey: json['labelKey'] as String? ?? '',
      score: (json['score'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      notApplicable: json['notApplicable'] as bool? ?? false,
    );
  }
}

/// One scoring band of a grid version: an absolute point interval and its colour.
class EvaluationReportLevelDto {
  final String label;
  final String color;
  final double minValue;
  final double maxValue;
  final int order;

  const EvaluationReportLevelDto({
    required this.label,
    required this.color,
    required this.minValue,
    required this.maxValue,
    required this.order,
  });

  factory EvaluationReportLevelDto.fromJson(Map<String, dynamic> json) {
    return EvaluationReportLevelDto(
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '',
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One column of the report: a single ISO week of one campaign, for one boutique.
class EvaluationReportWeekDto {
  final int? weekNumber;
  final DateTime weekStartDate;
  final int campaignId;
  final String campaignLibelle;
  final DateTime? campaignStartDate;
  final DateTime? campaignEndDate;
  final int versionNumber;
  final List<EvaluationReportCellDto> cells;

  /// Total points for the evaluation (sum of criteria scores).
  final double? averageScore;

  /// Highest total attainable in the version used this week.
  final double maxScore;
  final List<EvaluationReportLevelDto> levels;

  /// Evaluations folded into this column (>1 when campaigns overlapped on the week).
  final int mergedEvaluationCount;

  const EvaluationReportWeekDto({
    required this.weekNumber,
    required this.weekStartDate,
    required this.campaignId,
    required this.campaignLibelle,
    required this.campaignStartDate,
    required this.campaignEndDate,
    required this.versionNumber,
    required this.cells,
    required this.averageScore,
    required this.maxScore,
    required this.levels,
    required this.mergedEvaluationCount,
  });

  factory EvaluationReportWeekDto.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) => raw == null ? null : DateTime.tryParse(raw);

    return EvaluationReportWeekDto(
      weekNumber: (json['weekNumber'] as num?)?.toInt(),
      weekStartDate: parse(json['weekStartDate'] as String?) ?? DateTime.now(),
      campaignId: (json['campaignId'] as num?)?.toInt() ?? 0,
      campaignLibelle: json['campaignLibelle'] as String? ?? '',
      campaignStartDate: parse(json['campaignStartDate'] as String?),
      campaignEndDate: parse(json['campaignEndDate'] as String?),
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 0,
      cells: ((json['cells'] as List<dynamic>?) ?? const [])
          .map((c) => EvaluationReportCellDto.fromJson(c as Map<String, dynamic>))
          .toList(),
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 0,
      levels: ((json['levels'] as List<dynamic>?) ?? const [])
          .map((l) => EvaluationReportLevelDto.fromJson(l as Map<String, dynamic>))
          .toList(),
      mergedEvaluationCount: (json['mergedEvaluationCount'] as num?)?.toInt() ?? 1,
    );
  }

  EvaluationReportCellDto? cellFor(String labelKey) {
    for (final cell in cells) {
      if (cell.labelKey == labelKey) return cell;
    }
    return null;
  }

  bool get isMerged => mergedEvaluationCount > 1;

  /// The band the week's raw total falls into, taken from the version it was
  /// filled on. Bounds are inclusive and bands may touch (0–25, 25–40), so the
  /// earlier band wins on a boundary — same rule as the web report.
  EvaluationReportLevelDto? get level {
    final total = averageScore;
    if (total == null || levels.isEmpty) return null;

    final sorted = [...levels]..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.minValue.compareTo(b.minValue);
      });

    for (final lv in sorted) {
      if (total >= lv.minValue && total <= lv.maxValue) return lv;
    }

    // Outside every band: clamp to the nearest end instead of leaving it uncoloured.
    final highest = sorted.reduce((a, b) => b.maxValue > a.maxValue ? b : a);
    final lowest = sorted.reduce((a, b) => b.minValue < a.minValue ? b : a);
    return total > highest.maxValue ? highest : lowest;
  }

  /// Total as a share of the version's maximum, or null when it can't be measured.
  double? get ratio {
    final total = averageScore;
    if (total == null || maxScore <= 0) return null;
    return total / maxScore;
  }
}

class EvaluationReportBoutiqueDto {
  final int boutiqueId;
  final String boutiqueName;
  final List<EvaluationReportWeekDto> weeks;

  const EvaluationReportBoutiqueDto({
    required this.boutiqueId,
    required this.boutiqueName,
    required this.weeks,
  });

  factory EvaluationReportBoutiqueDto.fromJson(Map<String, dynamic> json) {
    return EvaluationReportBoutiqueDto(
      boutiqueId: (json['boutiqueId'] as num).toInt(),
      boutiqueName: json['boutiqueName'] as String? ?? '',
      weeks: ((json['weeks'] as List<dynamic>?) ?? const [])
          .map((w) => EvaluationReportWeekDto.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Simple mean of a criterion's scores across weeks. Weeks where the criterion
  /// didn't exist or wasn't scored contribute nothing rather than counting as zero.
  double? criterionAverage(String labelKey) {
    final scores = <int>[];
    for (final week in weeks) {
      final cell = week.cellFor(labelKey);
      if (cell == null || cell.notApplicable || cell.score == null) continue;
      scores.add(cell.score!);
    }
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}

class EvaluationReportTemplateDto {
  final int templateId;
  final String templateName;
  final List<EvaluationReportCriteriaDto> criteria;
  final List<EvaluationReportBoutiqueDto> boutiques;
  final double totalCoefficient;

  const EvaluationReportTemplateDto({
    required this.templateId,
    required this.templateName,
    required this.criteria,
    required this.boutiques,
    required this.totalCoefficient,
  });

  factory EvaluationReportTemplateDto.fromJson(Map<String, dynamic> json) {
    return EvaluationReportTemplateDto(
      templateId: (json['templateId'] as num).toInt(),
      templateName: json['templateName'] as String? ?? '',
      criteria: ((json['criteria'] as List<dynamic>?) ?? const [])
          .map((c) => EvaluationReportCriteriaDto.fromJson(c as Map<String, dynamic>))
          .toList(),
      boutiques: ((json['boutiques'] as List<dynamic>?) ?? const [])
          .map((b) => EvaluationReportBoutiqueDto.fromJson(b as Map<String, dynamic>))
          .toList(),
      totalCoefficient: (json['totalCoefficient'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Parses a '#RRGGBB' / '#RGB' band colour. Returns null for anything else.
Color? parseReportColor(String raw) {
  var value = raw.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
  return Color(int.parse('FF$value', radix: 16));
}
