import '../../incidents/models/Coefficient.dart';
import 'actionsModel.dart';
import 'choixReponseQuestion.dart';

class MissionAnswers {
  int missionId;
  int questionId;
  String? commentaire;
  String? fileName;
  DateTime? clouture;
  int? actionId;
  ActionM? actions;
  int? selectedResponseValue;
  double? questionCoefficient;
  int? reponseID;
  ChoixReponseQuestion? choixReponseQuestion;
  int? coefId;
  Coefficient? coefficient;
  String? jointureFichier;

  MissionAnswers({
    required this.missionId,
    required this.questionId,
    this.commentaire,
    this.fileName,
    this.clouture,
    this.actionId,
    this.actions,
    this.selectedResponseValue,
    this.questionCoefficient,
    this.reponseID,
    this.choixReponseQuestion,
    this.coefId,
    this.coefficient,
    this.jointureFichier,
  });

  // Factory method to create an instance from a JSON map
  factory MissionAnswers.fromJson(Map<String, dynamic> json) {
    return MissionAnswers(
      missionId: json['mission_id'] as int,
      questionId: json['question_id'] as int,
      commentaire: json['Commentaire'] as String?,
      fileName: json['fileName'] as String?,
      clouture: json['Clouture'] != null ? DateTime.parse(json['Clouture']) : null,
      actionId: json['ActionId'] as int?,
      actions: json['actions'] != null ? ActionM.fromJson(json['actions']) : null,
      selectedResponseValue: json['selectedResponseValue'] as int?,
      questionCoefficient: (json['questionCoefficient'] as num?)?.toDouble(),
      reponseID: json['reponseID'] as int?,
      choixReponseQuestion: json['choixReponseQuestion'] != null
          ? ChoixReponseQuestion.fromJson(json['choixReponseQuestion'])
          : null,
      coefId: json['coef_ID'] as int?,
      coefficient: json['coefficient'] != null ? Coefficient.fromJson(json['coefficient']) : null,
      jointureFichier: json['jointureFichier'] as String?,
    );
  }

  // Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'mission_id': missionId,
      'question_id': questionId,
      'Commentaire': commentaire,
      'fileName': fileName,
      'Clouture': clouture?.toIso8601String(),
      'ActionId': actionId,
      'actions': actions?.toJson(),
      'selectedResponseValue': selectedResponseValue,
      'questionCoefficient': questionCoefficient,
      'reponseID': reponseID,
      'choixReponseQuestion': choixReponseQuestion?.toJson(),
      'coef_ID': coefId,
      'coefficient': coefficient?.toJson(),
      'jointureFichier': jointureFichier,
    };
  }
}
