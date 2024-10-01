
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';

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
    this.reponseID
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
        reponseID: json['reponseID'] as int?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'sousMissionId': sousMissionId,
      'reponse': reponse,
      'clouture': clouture?.toIso8601String(), // Convert DateTime to ISO8601 string
      'actionId': actionId,
      'actions': actions?.toJson(), // Assuming ActionM has a toJson() method
      'commentaire': commentaire,
      'fileName': fileName,
      'reponseID' : reponseID,
    };
  }
}
