import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/incidentTypeModel.dart';

class QuestionMission {
  int id;
  String? description;
  int? sousMissionId;
  String? reponse;
  DateTime? clouture;
  int? actionId;
  ActionM? actions;
  String? commentaire;
  String? fileName;
  ChoixReponseQuestion? choixReponseQuestion;
  int? reponseID;
  int? selectedResponseValue;
  double? questionCoefficient;
  bool? incident;
  String? jointureFichier;
  int? coef_ID;
  int? problemId;
  int? incidentTypeId;
  IncidentType? incidentType;


  QuestionMission({
    required this.id,
    this.description,
    this.sousMissionId,
    this.reponse,
    this.clouture,
    this.actionId,
    this.actions,
    this.commentaire,
    this.fileName,
    this.choixReponseQuestion,
    this.reponseID,
    this.selectedResponseValue,
    this.questionCoefficient,
    this.incident,
    this.jointureFichier,
    this.coef_ID,
    this.problemId,
    this.incidentTypeId,
    this.incidentType
  });

  factory QuestionMission.fromJson(Map<String, dynamic> json) {
    return QuestionMission(
      id: json['id'] as int,
      description: json['description'] as String?,
      sousMissionId: json['sousMissionId'] as int?,
      reponse: json['reponse'] as String?,
      clouture: json['clouture'] != null ? DateTime.parse(json['clouture']) : null,
      actionId: json['actionId'] as int?,
      actions: json['actions'] != null ? ActionM.fromJson(json['actions']) : null,
      commentaire: json['commentaire'] as String?,
      fileName: json['fileName'] as String?,
      choixReponseQuestion: json['choixReponseQuestion'] != null ? ChoixReponseQuestion.fromJson(json['choixReponseQuestion']) : null,
      reponseID: json['reponseID'] as int?,
      selectedResponseValue: json['selectedResponseValue'] as int?,
      questionCoefficient: (json['questionCoefficient'] as num?)?.toDouble(),
      incident: json['incident'] as bool?,
      jointureFichier: json['jointureFichier'] as String?,
      coef_ID: json['coef_ID'] as int?,
      problemId: json['problemId'] as int?,
      incidentTypeId: json['incidentTypeId'] as int?,
      incidentType: json['incidentType'] != null ? IncidentType.fromJson(json['incidentType']) : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'sousMissionId': sousMissionId,
      'reponse': reponse,
      'clouture': clouture?.toIso8601String(),
      'actionId': actionId,
      'actions': actions?.toJson(),
      'commentaire': commentaire,
      'fileName': fileName,
      'choixReponseQuestion': choixReponseQuestion?.toJson(),
      'reponseID': reponseID,
      'selectedResponseValue': selectedResponseValue,
      'questionCoefficient': questionCoefficient,
      'incident': incident,
      'jointureFichier':jointureFichier,
      'coef_ID':coef_ID,
      'problemId':problemId,
      'incidentTypeId': incidentTypeId,
      'incidentType': incidentType?.toJson(),

    };
  }
}
