import '../../incidents/models/Coefficient.dart';
import 'CategoryQuestions.dart';
import 'Checklist.dart';

class ChecklistCategory {
  int id;
  String? code;
  String? libelle;
  String? description;
  DateTime? dateCreation;
  int missionId;
  Checklist? mission;
  List<CategoryQuestions>? missionQuestions;
  double? selectedCoefficientValue;
  double scoreMax;
  int nombreQuestion;
  int? coefficientId;
  Coefficient? coefficient;

  ChecklistCategory({
    required this.id,
    this.code,
    this.libelle,
    this.description,
    this.dateCreation,
    required this.missionId,
    this.mission,
    this.missionQuestions,
    this.selectedCoefficientValue,
    this.scoreMax = 0.0,
    this.nombreQuestion = 0,
    this.coefficientId,
    this.coefficient,
  });

  // Factory method to create an instance from a JSON map
  factory ChecklistCategory.fromJson(Map<String, dynamic> json) {
    return ChecklistCategory(
      id: json['id'] as int,
      code: json['code'] as String?,
      libelle: json['libelle'] as String?,
      description: json['description'] as String?,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation']) : null,
      missionId: json['missionId'] as int,
      mission: json['mission'] != null ? Checklist.fromJson(json['mission']) : null,
      missionQuestions: json['missionQuestions'] != null
          ? (json['missionQuestions'] as List)
          .map((e) => CategoryQuestions.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
      selectedCoefficientValue: (json['selectedCoefficientValue'] as num?)?.toDouble(),
      scoreMax: (json['scoreMax'] as num).toDouble(),
      nombreQuestion: json['nombreQuestion'] as int,
      coefficientId: json['coefficient_ID'] as int?,
      coefficient: json['coefficient'] != null ? Coefficient.fromJson(json['coefficient']) : null,
    );
  }

  // Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'libelle': libelle,
      'description': description,
      'dateCreation': dateCreation?.toIso8601String(),
      'missionId': missionId,
      'mission': mission?.toJson(),
      'missionQuestions': missionQuestions?.map((e) => e.toJson()).toList(),
      'selectedCoefficientValue': selectedCoefficientValue,
      'scoreMax': scoreMax,
      'nombreQuestion': nombreQuestion,
      'coefficient_ID': coefficientId,
      'coefficient': coefficient?.toJson(),
    };
  }
}
