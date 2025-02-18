import 'ChecklistCategory.dart';

class Checklist {
  int id;
  String? libelle;
  String? missionCode;
  String? description;
  DateTime? createdAt;
  double scoreMax;
  int? totalQuestion;
  List<ChecklistCategory>? sousMissions;

  Checklist({
    required this.id,
    this.libelle,
    this.missionCode,
    this.description,
    this.createdAt,
    required this.scoreMax,
    this.totalQuestion,
    this.sousMissions,
  });

  // Factory method to create an instance from a JSON map
  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] as int,
      libelle: json['libelle'] as String?,
      missionCode: json['missionCode'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      scoreMax: (json['scoreMax'] as num).toDouble(),
      totalQuestion: json['totalQuestion'] as int?,
      sousMissions: json['sousMissions'] != null
          ? (json['sousMissions'] as List)
          .map((e) => ChecklistCategory.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }

  // Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'missionCode': missionCode,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'scoreMax': scoreMax,
      'totalQuestion': totalQuestion,
      'sousMissions': sousMissions?.map((e) => e.toJson()).toList(),
    };
  }
}
