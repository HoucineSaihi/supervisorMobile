class Checklist {
  int id;
  String? libelle;
  String? missionCode;
  String? description;
  DateTime? createdAt;
  double scoreMax;
  int? totalQuestion;

  Checklist({
    required this.id,
    this.libelle,
    this.missionCode,
    this.description,
    this.createdAt,
    required this.scoreMax,
    this.totalQuestion,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      libelle: json['libelle'],
      missionCode: json['missionCode'],
      description: json['description'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      scoreMax: json['scoreMax'].toDouble(), // Ensure it's a double
      totalQuestion: json['totalQuestion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'missionCode': missionCode,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'scoreMax': scoreMax,
      'totalQuestion': totalQuestion,
    };
  }
}
