import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';

class SousMission {
  int? id;
  String? libelle;
  String? code;
  String? description;
  DateTime? dateCreation;
  int? missionId;
  List<QuestionMission>? missionQuestions;

  int? sommeValeurPositive;
  double? sommeCalculPoint;
  double? scoreMax;
  double? tauxConformiteCategorie;
  int? nombreQuestion;
  int? coefficient_ID;
  double? selectedCoefficient;

  SousMission({
    this.id,
    this.libelle,
    this.code,
    this.description,
    this.dateCreation,
    this.missionId,
    this.missionQuestions,
    this.sommeValeurPositive,
    this.sommeCalculPoint,
    this.scoreMax,
    this.tauxConformiteCategorie,
    this.nombreQuestion,
    this.coefficient_ID,
    this.selectedCoefficient
  });

  factory SousMission.fromJson(Map<String, dynamic> json) {
    return SousMission(
      id: json['id'] as int?,
      libelle: json['libelle'] as String?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation']) : null,
      missionId: json['missionId'] as int?,
      missionQuestions: json['missionQuestions'] != null
          ? (json['missionQuestions'] as List).map((i) => QuestionMission.fromJson(i)).toList()
          : null,
      sommeValeurPositive: json['sommeValeurPositive'] as int?,
      sommeCalculPoint: (json['sommeCalculPoint'] as num?)?.toDouble(),
      scoreMax: (json['scoreMax'] as num?)?.toDouble(),
      tauxConformiteCategorie: (json['tauxConformiteCategorie'] as num?)?.toDouble(),
        nombreQuestion : (json['nombreQuestion'] as int?),
        coefficient_ID : (json['coefficient_ID'] as int?),
        selectedCoefficient : (json['selectedCoefficient'] as num?)?.toDouble()
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'code': code,
      'description': description,
      'dateCreation': dateCreation?.toIso8601String(),
      'missionId': missionId,
      'missionQuestions': missionQuestions?.map((q) => q.toJson()).toList(),
      'sommeValeurPositive': sommeValeurPositive,
      'sommeCalculPoint': sommeCalculPoint,
      'scoreMax': scoreMax,
      'tauxConformiteCategorie': tauxConformiteCategorie,
      'nombreQuestion':nombreQuestion,
      'coefficient_ID':coefficient_ID,
      'selectedCoefficient':selectedCoefficient
    };
  }
}
