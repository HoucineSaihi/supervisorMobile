import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';

import '../../Profile/models/group_model.dart';
import '../../incidents/models/Coefficient.dart';

import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import '../../incidents/models/Coefficient.dart';

class Problem {
  int id;
  int? userId;
  UserModel? user;
  int? assignedTo;
  UserModel? assignedUser;
  int boutiqueId;
  BoutiqueModel? boutique;
  String description;
  String? commentaire;
  String? problemImageBefore;
  String? problemImageAfter;
  String? jointFileBefore;
  String? jointFileAfter;
  int? coefId;
  Coefficient? coefficient;
  int? cluster; // 0 = Retail, 1 = Hospitality
  int? origin; // 0 = Checklist, 1 = Libre
  DateTime? declarationDate;
  DateTime? planifiedTo;
  DateTime? planifiedAt;
  DateTime? closedDate;
  String? closingComment;
  double? cost;
  int? departementId;
  Group? departement;
  int? statusType;
  int? status;

  Problem({
    required this.id,
    this.userId,
    this.user,
    this.assignedTo,
    this.assignedUser,
    required this.boutiqueId,
    this.boutique,
    required this.description,
    this.commentaire,
    this.problemImageBefore,
    this.problemImageAfter,
    this.jointFileBefore,
    this.jointFileAfter,
    this.coefId,
    this.coefficient,
    this.cluster,
    this.origin,
    this.declarationDate,
    this.planifiedTo,
    this.planifiedAt,
    this.closedDate,
    this.closingComment,
    this.cost,
    this.departementId,
    this.departement,
    this.statusType,
    this.status,
  });

  /// Factory constructor to create an instance from JSON
  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] ?? 0,
      userId: json['user_id'] as int?,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      assignedTo: json['assigned_to'] as int?,
      assignedUser: json['assignedUser'] != null ? UserModel.fromJson(json['assignedUser']) : null,
      boutiqueId: json['boutique_id'] ?? 0,
      boutique: json['boutique'] != null ? BoutiqueModel.fromJson(json['boutique']) : null,
      description: json['description'] ?? '',
      commentaire: json['commentaire'] as String?,
      problemImageBefore: json['problem_image_before'] as String?,
      problemImageAfter: json['problem_image_after'] as String?,
      jointFileBefore: json['joint_file_before'] as String?,
      jointFileAfter: json['joint_file_after'] as String?,
      coefId: json['coef_id'] as int?,
      coefficient: json['coefficient'] != null ? Coefficient.fromJson(json['coefficient']) : null,
      cluster: json['cluster'] as int?,
      origin: json['origin'] as int?,
      declarationDate: json['declaration_date'] != null ? DateTime.tryParse(json['declaration_date']) : null,
      planifiedTo: json['planified_to'] != null ? DateTime.tryParse(json['planified_to']) : null,
      planifiedAt: json['planified_at'] != null ? DateTime.tryParse(json['planified_at']) : null,
      closedDate: json['closed_date'] != null ? DateTime.tryParse(json['closed_date']) : null,
      closingComment: json['closing_comment'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      departementId: json['departement_id'] as int?,
      departement: json['departement'] != null ? Group.fromJson(json['departement']) : null,
      statusType: json['StatusType']  as int?,
      status: json['Status'] as int?,
    );
  }

  /// Convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user?.toJson(),
      'assigned_to': assignedTo,
      'assignedUser': assignedUser?.toJson(),
      'boutique_id': boutiqueId,
      'boutique': boutique?.toJson(),
      'description': description,
      'commentaire': commentaire,
      'problem_image_before': problemImageBefore,
      'problem_image_after': problemImageAfter,
      'joint_file_before': jointFileBefore,
      'joint_file_after': jointFileAfter,
      'coef_id': coefId,
      'coefficient': coefficient?.toJson(),
      'cluster': cluster,
      'origin': origin,
      'declaration_date': declarationDate?.toIso8601String(),
      'planified_to': planifiedTo?.toIso8601String(),
      'planified_at': planifiedAt?.toIso8601String(),
      'closed_date': closedDate?.toIso8601String(),
      'closing_comment': closingComment,
      'cost': cost,
      'departement_id': departementId,
      'departement': departement?.toJson(),
      'StatusType': statusType,
      'Status': status,
    };
  }
}
