// ─────────────────────────────────────────────────────────
// vm_campaign_dto.dart
// Traduit la réponse JSON du backend en objets Dart.
// Endpoint : POST /api/VmCompaign/by-sites
// ─────────────────────────────────────────────────────────

// ── Statut de la campagne ──────────────────────────────
// On convertit la string du backend en enum lisible.
enum CampaignStatus {
  notStarted, // 'Planified'
  inProgress, // 'InProgress'
  submitted,  // 'Completed'
  cancelled,  // 'Cancelled'
  unknown,
}

// Helper : convertit la string du JSON en enum
CampaignStatus campaignStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'planified':
      return CampaignStatus.notStarted;
    case 'inprogress':
      return CampaignStatus.inProgress;
    case 'completed':
      return CampaignStatus.submitted;
    case 'cancelled':
      return CampaignStatus.cancelled;
    default:
      return CampaignStatus.unknown;
  }
}

// Helper : convertit l'int du JSON en enum (pour compatibilité)
CampaignStatus campaignStatusFromInt(int value) {
  switch (value) {
    case 0:
      return CampaignStatus.notStarted;
    case 1:
      return CampaignStatus.inProgress;
    case 2:
      return CampaignStatus.submitted;
    case 3:
      return CampaignStatus.cancelled;
    default:
      return CampaignStatus.unknown;
  }
}

// ── Zone ───────────────────────────────────────────────
// Correspond à un élément de "zoneStats" dans le JSON
class ZoneStatDto {
  final int zoneId;
  final String zoneName;
  final String zoneCode;
  final int imagesCount;
  final bool isFinished;

  const ZoneStatDto({
    required this.zoneId,
    required this.zoneName,
    required this.zoneCode,
    required this.imagesCount,
    required this.isFinished,
  });

  // Lit un Map (JSON parsé) et construit un ZoneStatDto
  factory ZoneStatDto.fromJson(Map<String, dynamic> json) {
    final imagesCount = (json['imagesCount'] as num?)?.toInt() ?? 0;
    return ZoneStatDto(
      zoneId: (json['zoneId'] as num?)?.toInt() ?? 0,
      zoneName: json['zoneName'] as String? ?? '',
      zoneCode: json['zoneCode'] as String? ?? '',
      imagesCount: imagesCount,
      // by-sites API no longer provides isFinished; derive from imagesCount
      isFinished: imagesCount > 0,
    );
  }

  // ── Propriétés calculées ──────────────────────────────
  // Est-ce que la zone a au moins une photo mais n'est pas finie ?
  bool get isPartial => imagesCount > 0 && !isFinished;

  // Est-ce que la zone n'a aucune photo ?
  bool get isEmpty => imagesCount == 0 && !isFinished;
}

// ── Execution Stats ────────────────────────────────────
// Correspond à "executionsStats" dans le JSON
// Contient les infos du guideline + la liste des zones
class ExecutionStatsDto {
  final int guidelineId;
  final String? guidelineName;
  final String? guidelineDescription;
  final List<ZoneStatDto> zoneStats;

  const ExecutionStatsDto({
    required this.guidelineId,
    this.guidelineName,
    this.guidelineDescription,
    required this.zoneStats,
  });

  factory ExecutionStatsDto.fromJson(Map<String, dynamic> json) {
    // json['zoneStats'] est une List → on mappe chaque élément
    final rawZones = (json['zoneStats'] as List<dynamic>?) ?? <dynamic>[];
    final zones = rawZones
        .map((z) => ZoneStatDto.fromJson(z as Map<String, dynamic>))
        .toList();

    return ExecutionStatsDto(
      guidelineId:          json['guidelineId']          as int,
      guidelineName:        json['guidelineName']        as String?,
      guidelineDescription: json['guidelineDescription'] as String?,
      zoneStats:            zones,
    );
  }

  // ── Propriétés calculées ──────────────────────────────

  // Nombre de zones complètement finies
  int get completedZones => zoneStats.where((z) => z.isFinished).length;

  // Nombre total de zones
  int get totalZones => zoneStats.length;

  // Total des photos uploadées sur toutes les zones
  int get totalImages => zoneStats.fold(0, (sum, z) => sum + z.imagesCount);

  // Ratio de complétion (0.0 → 1.0)
  // Ex: 3 zones finies sur 5 → 0.6 → 60%
  double get completionRatio =>
      totalZones == 0 ? 0.0 : completedZones / totalZones;
}

// ── Campaign ───────────────────────────────────────────
// Correspond à un élément racine du tableau JSON
class VmCampaignDto {
  final int campaignId;
  final int siteId;
  final CampaignStatus status;
  final DateTime endDate;
  final String libelle;
  final int zoneCount;
  final bool containsGuideline;
  final List<ExecutionStatsDto> executionsStats; // Maintenant une liste

  const VmCampaignDto({
    required this.campaignId,
    required this.siteId,
    required this.status,
    required this.endDate,
    required this.libelle,
    required this.zoneCount,
    required this.containsGuideline,
    required this.executionsStats,
  });

  factory VmCampaignDto.fromJson(Map<String, dynamic> json) {
    // Le status peut venir comme string ou int (pour compatibilité)
    CampaignStatus status;
    if (json['status'] is String) {
      status = campaignStatusFromString(json['status'] as String);
    } else if (json['status'] is int) {
      // Fallback pour compatibilité si jamais c'est encore un int
      status = campaignStatusFromInt(json['status'] as int);
    } else {
      status = CampaignStatus.unknown;
    }

    // executionsStats est maintenant une liste
    final rawExecutionsStats =
        (json['executionsStats'] as List<dynamic>?) ?? <dynamic>[];
    final executionsStatsList = rawExecutionsStats
        .map((e) => ExecutionStatsDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return VmCampaignDto(
      campaignId:        json['compaignId']       as int,
      siteId:            (json['siteId'] as num?)?.toInt() ?? 0,
      status:            status,
      // Le backend envoie une string ISO 8601 → on la parse en DateTime
      endDate:           DateTime.parse(json['endDate'] as String),
      libelle:           json['libelle']           as String,
      zoneCount:         json['zoneCount']         as int,
      containsGuideline: json['containsGuideline'] as bool,
      executionsStats:   executionsStatsList,
    );
  }

  // ── Propriétés calculées ──────────────────────────────

  // Nombre de jours restants avant la deadline
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  // Est-ce que la deadline est dépassée ?
  bool get isOverdue => DateTime.now().isAfter(endDate);

  // Toutes les zones de tous les guidelines
  List<ZoneStatDto> get allZones {
    return executionsStats.expand((stats) => stats.zoneStats).toList();
  }

  // Nombre total de zones complétées (tous guidelines confondus)
  int get totalCompletedZones {
    return allZones.where((z) => z.isFinished).length;
  }

  // Nombre total de zones (tous guidelines confondus)
  int get totalZones {
    return allZones.length;
  }

  // Total des photos uploadées (tous guidelines confondus)
  int get totalImages {
    return allZones.fold(0, (sum, z) => sum + z.imagesCount);
  }

  // Ratio de complétion global (0.0 → 1.0)
  double get completionRatio {
    return totalZones == 0 ? 0.0 : totalCompletedZones / totalZones;
  }

  // Peut-on soumettre ? (toutes les zones de tous les guidelines finies)
  bool get canSubmit {
    return allZones.every((z) => z.isFinished);
  }

  // Helper pour compatibilité : retourne le premier guideline (si existe)
  // Utilisé pour l'affichage dans certains widgets
  ExecutionStatsDto? get firstGuideline {
    return executionsStats.isNotEmpty ? executionsStats.first : null;
  }

  VmCampaignDto copyWith({
    CampaignStatus? status,
    List<ExecutionStatsDto>? executionsStats,
  }) {
    return VmCampaignDto(
      campaignId: campaignId,
      siteId: siteId,
      status: status ?? this.status,
      endDate: endDate,
      libelle: libelle,
      zoneCount: zoneCount,
      containsGuideline: containsGuideline,
      executionsStats: executionsStats ?? this.executionsStats,
    );
  }
}