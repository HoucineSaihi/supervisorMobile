import '../../incidents/models/Coefficient.dart';
import 'ChecklistCategory.dart';
import 'MissionAnswers.dart';

class CategoryQuestions {
  int id;
  String? description;
  int sousMissionId;
  ChecklistCategory? sousMission;
  int? coefId;
  Coefficient? coefficient;
  List<MissionAnswers> missionAnswers;

  CategoryQuestions({
    required this.id,
    this.description,
    required this.sousMissionId,
    this.sousMission,
    this.coefId,
    this.coefficient,
    this.missionAnswers = const [],
  });

  // Factory method to create an instance from a JSON map
  factory CategoryQuestions.fromJson(Map<String, dynamic> json) {
    return CategoryQuestions(
      id: json['id'] as int,
      description: json['description'] as String?,
      sousMissionId: json['sousMissionId'] as int,
      sousMission: json['sousMission'] != null ? ChecklistCategory.fromJson(json['sousMission']) : null,
      coefId: json['coef_ID'] as int?,
      coefficient: json['coefficient'] != null ? Coefficient.fromJson(json['coefficient']) : null,
      missionAnswers: json['missionAnswers'] != null
          ? (json['missionAnswers'] as List)
          .map((e) => MissionAnswers.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }

  // Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'sousMissionId': sousMissionId,
      'sousMission': sousMission?.toJson(),
      'coef_ID': coefId,
      'coefficient': coefficient?.toJson(),
      'missionAnswers': missionAnswers.map((e) => e.toJson()).toList(),
    };
  }
}
