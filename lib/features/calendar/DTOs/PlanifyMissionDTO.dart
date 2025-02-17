class PlanifyMissionDTO {
  DateTime planifiedAt;
  int posId;
  int assignementId;

  PlanifyMissionDTO({
    required this.planifiedAt,
    required this.posId,
    required this.assignementId,
  });

  // Convert from JSON to PlanifyMissionDTO
  factory PlanifyMissionDTO.fromJson(Map<String, dynamic> json) {
    return PlanifyMissionDTO(
      planifiedAt: DateTime.parse(json['planified_at']),
      posId: json['pos_id'],
      assignementId: json['assignement_id'],
    );
  }

  // Convert PlanifyMissionDTO to JSON
  Map<String, dynamic> toJson() {
    return {
      'planified_at': planifiedAt.toIso8601String(),
      'pos_id': posId,
      'assignement_id': assignementId,
    };
  }
}
