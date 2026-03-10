// ─────────────────────────────────────────────────────────
// vm_campaign_dto.dart
// Traduit la réponse JSON du backend en objets Dart.
// Endpoint : POST /api/VmCompaign/by-sites
// ─────────────────────────────────────────────────────────

// ── Statut de la campagne ──────────────────────────────
// On convertit l'entier du backend en enum lisible.
// 0 = pas encore démarrée, 1 = en cours
enum CampaignStatus {
  notStarted, // status == 0
  inProgress, // status == 1
  submitted,  // status == 2 (pour plus tard)
  unknown,
}

// Helper : convertit l'int du JSON en enum
CampaignStatus campaignStatusFromInt(int value) {
  switch (value) {
    case 0:
      return CampaignStatus.notStarted;
    case 1:
      return CampaignStatus.inProgress;
    case 2:
      return CampaignStatus.submitted;
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
    return ZoneStatDto(
      zoneId:      json['zoneId']      as int,
      zoneName:    json['zoneName']    as String,
      zoneCode:    json['zoneCode']    as String,
      imagesCount: json['imagesCount'] as int,
      isFinished:  json['isFinished']  as bool,
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
  final String guidelineName;
  final String guidelineDescription;
  final List<ZoneStatDto> zoneStats;

  const ExecutionStatsDto({
    required this.guidelineId,
    required this.guidelineName,
    required this.guidelineDescription,
    required this.zoneStats,
  });

  factory ExecutionStatsDto.fromJson(Map<String, dynamic> json) {
    // json['zoneStats'] est une List → on mappe chaque élément
    final rawZones = json['zoneStats'] as List<dynamic>;
    final zones = rawZones
        .map((z) => ZoneStatDto.fromJson(z as Map<String, dynamic>))
        .toList();

    return ExecutionStatsDto(
      guidelineId:          json['guidelineId']          as int,
      guidelineName:        json['guidelineName']        as String,
      guidelineDescription: json['guidelineDescription'] as String,
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
  final CampaignStatus status;
  final DateTime endDate;
  final String libelle;
  final int zoneCount;
  final bool containsGuideline;
  final ExecutionStatsDto executionStats;

  const VmCampaignDto({
    required this.campaignId,
    required this.status,
    required this.endDate,
    required this.libelle,
    required this.zoneCount,
    required this.containsGuideline,
    required this.executionStats,
  });

  factory VmCampaignDto.fromJson(Map<String, dynamic> json) {
    return VmCampaignDto(
      campaignId:        json['compaignId']       as int,
      status:            campaignStatusFromInt(json['status'] as int),
      // Le backend envoie une string ISO 8601 → on la parse en DateTime
      endDate:           DateTime.parse(json['endDate'] as String),
      libelle:           json['libelle']           as String,
      zoneCount:         json['zoneCount']         as int,
      containsGuideline: json['containsGuideline'] as bool,
      executionStats:    ExecutionStatsDto.fromJson(
          json['executionsStats'] as Map<String, dynamic>),
    );
  }

  // ── Propriétés calculées ──────────────────────────────

  // Nombre de jours restants avant la deadline
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  // Est-ce que la deadline est dépassée ?
  bool get isOverdue => DateTime.now().isAfter(endDate);

  // Peut-on soumettre ? (toutes les zones finies)
  bool get canSubmit =>
      executionStats.zoneStats.every((z) => z.isFinished);
}