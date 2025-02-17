import '../../Profile/models/user_model.dart';
import 'Checklist.dart';

class UserChecklistAssignment {
  int id;
  int userId;
  UserModel? user;
  int checklistId;
  Checklist? checklist;
  int modelReponseQuestionId;
  int conformiteId;

  UserChecklistAssignment({
    required this.id,
    required this.userId,
    this.user,
    required this.checklistId,
    this.checklist,
    required this.modelReponseQuestionId,
    required this.conformiteId,
  });

  factory UserChecklistAssignment.fromJson(Map<String, dynamic> json) {
    return UserChecklistAssignment(
      id: json['id'],
      userId: json['user_id'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      checklistId: json['checklist_id'],
      checklist: json['checklist'] != null ? Checklist.fromJson(json['checklist']) : null,
      modelReponseQuestionId: json['modelReponseQuestionId'],
      conformiteId: json['conformite_ID'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user?.toJson(),
      'checklist_id': checklistId,
      'checklist': checklist?.toJson(),
      'modelReponseQuestionId': modelReponseQuestionId,
      'conformite_ID': conformiteId,

    };
  }
}
