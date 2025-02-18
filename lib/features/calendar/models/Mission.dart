import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/calendar/models/modelReponseQuestion.dart';

import 'Checklist.dart';
import 'MissionAnswers.dart';

class Mission {
  int id;
  List<MissionAnswers>? missionAnswers;
  int checklistId;
  Checklist checklist;
  DateTime? createdAt;
  DateTime? startedAt;
  DateTime? planifiedAt;
  DateTime? endedAt;
  bool? activated;
  int? userId;
  int status;
  UserModel? user;
  int? boutiqueId;
  double scoreMax;
  int? totalQuestion;
  double? tauxConformite;
  int modelReponseQuestionId;
  ModeleReponseQuestion? modeleReponseQuestion;
  int conformiteId;
  int totalIncidents;
  double progression;
  Mission({
    required this.id,
    this.missionAnswers,
    required this.checklistId,
    required this.checklist,
    this.createdAt,
    this.startedAt,
    this.planifiedAt,
    this.endedAt,
    this.activated,
    this.userId,
    required this.status,
    this.user,
    this.boutiqueId,

    required this.scoreMax,
    this.totalQuestion,
    this.tauxConformite,
    required this.modelReponseQuestionId,
    this.modeleReponseQuestion,
    required this.conformiteId,
    this.totalIncidents = 0,
    this.progression = 0,
  });

  // Convert from JSON
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as int,
      missionAnswers: (json['MissionAnswers'] as List<dynamic>?)
          ?.map((e) => MissionAnswers.fromJson(e))
          .toList(),
      checklistId: json['checklist_id'] as int,
      checklist: Checklist.fromJson(json['checklist']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      startedAt: json['startedAT'] != null ? DateTime.parse(json['startedAT']) : null,
      planifiedAt: json['planifiedAt'] != null ? DateTime.parse(json['planifiedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      activated: json['activated'] as bool?,
      userId: json['userId'] as int?,
      status: json['status'] as int,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      boutiqueId: json['BoutiqueId'] as int?,

      scoreMax: (json['scoreMax'] as num).toDouble(),
      totalQuestion: json['totalQuestion'] as int?,
      tauxConformite: (json['tauxConformite'] as num?)?.toDouble(),
      modelReponseQuestionId: json['modelReponseQuestionId'] as int,
      modeleReponseQuestion: json['modeleReponseQuestion'] != null
          ? ModeleReponseQuestion.fromJson(json['modeleReponseQuestion'])
          : null,
      conformiteId: json['conformite_ID'] as int,
      totalIncidents: json['totalIncidents'] as int? ?? 0,
      progression: (json['progression'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'MissionAnswers': missionAnswers?.map((e) => e.toJson()).toList(),
      'checklist_id': checklistId,
      'checklist': checklist.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'startedAT': startedAt?.toIso8601String(),
      'planifiedAt': planifiedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'activated': activated,
      'userId': userId,
      'status': status,
      'user': user?.toJson(),
      'BoutiqueId': boutiqueId,
      'scoreMax': scoreMax,
      'totalQuestion': totalQuestion,
      'tauxConformite': tauxConformite,
      'modelReponseQuestionId': modelReponseQuestionId,
      'modeleReponseQuestion': modeleReponseQuestion?.toJson(),
      'conformite_ID': conformiteId,
      'totalIncidents': totalIncidents,
      'progression': progression,
    };
  }
}
