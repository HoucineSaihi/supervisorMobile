import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';

import '../../Profile/models/group_model.dart';
import '../../incidents/models/Coefficient.dart';

import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import '../../incidents/models/Coefficient.dart';
import '../../incidents/models/IncidentCategory.dart';

class Problem {
  int id;
  int? user_id;  // Renamed to match C# field 'user_id'
  UserModel? user;  // Renamed to match C# field 'user'
  int? assigned_to;  // Renamed to match C# field 'assigned_to'
  UserModel? assignedUser;  // Renamed to match C# field 'assignedUser'
  int boutique_id;  // Renamed to match C# field 'boutique_id'
  BoutiqueModel? boutique;  // Renamed to match C# field 'boutique'
  String description;  // Unchanged, as it's already matching
  String? commentaire;  // Unchanged, as it's already matching
  String? problem_image_before;  // Renamed to match C# field 'problem_image_before'
  String? problem_image_after;  // Renamed to match C# field 'problem_image_after'
  String? joint_file_before;  // Renamed to match C# field 'joint_file_before'
  String? joint_file_after;  // Renamed to match C# field 'joint_file_after'
  int? coef_id;  // Renamed to match C# field 'coef_id'
  Coefficient? coefficient;  // Renamed to match C# field 'coefficient'
  int? cluster;  // Unchanged, as it's already matching
  int? origin;  // Unchanged, as it's already matching
  DateTime? declaration_date;  // Renamed to match C# field 'declaration_date'
  DateTime? planified_to;  // Unchanged, as it's already matching
  DateTime? planified_at;  // Unchanged, as it's already matching
  DateTime? closed_date;  // Renamed to match C# field 'closed_date'
  String? closing_comment;  // Renamed to match C# field 'closing_comment'
  double? cost;  // Changed to `double?` for C# compatibility
  int? departement_id;  // Renamed to match C# field 'departement_id'
  Group? departement;  // Renamed to match C# field 'departement'
  int? StatusType;  // Renamed to match C# field 'StatusType'
  int? Status;  // Renamed to match C# field 'Status'
  IncidentCategory? type;


  Problem({
    required this.id,
    this.user_id,
    this.user,
    this.assigned_to,
    this.assignedUser,
    required this.boutique_id,
    this.boutique,
    required this.description,
    this.commentaire,
    this.problem_image_before,
    this.problem_image_after,
    this.joint_file_before,
    this.joint_file_after,
    this.coef_id,
    this.coefficient,
    this.cluster,
    this.origin,
    this.declaration_date,
    this.planified_to,
    this.planified_at,
    this.closed_date,
    this.closing_comment,
    this.cost,
    this.departement_id,
    this.departement,
    this.StatusType,
    this.Status,
    this.type
  });

  // Adjust the factory constructor to reflect the C# names.
  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] ?? 0,
      user_id: json['user_id'] as int?,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      assigned_to: json['assigned_to'] as int?,
      assignedUser: json['assignedUser'] != null ? UserModel.fromJson(json['assignedUser']) : null,
      boutique_id: json['boutique_id'] ?? 0,
      boutique: json['boutique'] != null ? BoutiqueModel.fromJson(json['boutique']) : null,
      description: json['description'] ?? '',
      commentaire: json['commentaire'] as String?,
      problem_image_before: json['problem_image_before'] as String?,
      problem_image_after: json['problem_image_after'] as String?,
      joint_file_before: json['joint_file_before'] as String?,
      joint_file_after: json['joint_file_after'] as String?,
      coef_id: json['coef_id'] as int?,
      coefficient: json['coefficient'] != null ? Coefficient.fromJson(json['coefficient']) : null,
      cluster: json['cluster'] as int?,
      origin: json['origin'] as int?,
      declaration_date: json['declaration_date'] != null ? DateTime.tryParse(json['declaration_date']) : null,
      planified_to: json['planified_to'] != null ? DateTime.tryParse(json['planified_to']) : null,
      planified_at: json['planified_at'] != null ? DateTime.tryParse(json['planified_at']) : null,
      closed_date: json['closed_date'] != null ? DateTime.tryParse(json['closed_date']) : null,
      closing_comment: json['closing_comment'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      departement_id: json['departement_id'] as int?,
      departement: json['departement'] != null ? Group.fromJson(json['departement']) : null,
      StatusType: json['statusType'] as int?,
      Status: json['status'] as int?,
      type: json['type'] != null ? IncidentCategoryExtension.fromString(json['type']) : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': user_id,
      'user': user?.toJson(),
      'assigned_to': assigned_to,
      'assignedUser': assignedUser?.toJson(),
      'boutique_id': boutique_id,
      'boutique': boutique?.toJson(),
      'description': description,
      'commentaire': commentaire,
      'problem_image_before': problem_image_before,
      'problem_image_after': problem_image_after,
      'joint_file_before': joint_file_before,
      'joint_file_after': joint_file_after,
      'coef_id': coef_id,
      'coefficient': coefficient?.toJson(),
      'cluster': cluster,
      'origin': origin,
      'declaration_date': declaration_date?.toIso8601String(),
      'planified_to': planified_to?.toIso8601String(),
      'planified_at': planified_at?.toIso8601String(),
      'closed_date': closed_date?.toIso8601String(),
      'closing_comment': closing_comment,
      'cost': cost,
      'departement_id': departement_id,
      'departement': departement?.toJson(),
      'StatusType': StatusType,
      'Status': Status,
      'type': type?.value,

    };
  }
}

