import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';

import '../../incidents/models/Coefficient.dart';

class Problem {
  int id;
  int userId;
  //Caisse? user;
  int boutiqueId;
  BoutiqueModel? boutique;
  String? description;
  String? commentaire;
  String? problemImageBefore;
  String? problemImageAfter;
  String? jointFileBefore;
  String? jointFileAfter;
  int coefId;
  Coefficient? coefficient;
  int cluster; // 0 = Retail, 1 = Hospitality
  int origin; // 0 = Checklist, 1 = Libre
  DateTime declarationDate;
  DateTime? closedDate;
  int statut;
  String? closingComment;
  double cost;

  Problem({
    required this.id,
    required this.userId,
    //this.user,
    required this.boutiqueId,
    this.boutique,
    this.description,
    this.commentaire,
    this.problemImageBefore,
    this.problemImageAfter,
    this.jointFileBefore,
    this.jointFileAfter,
    required this.coefId,
    this.coefficient,
    required this.cluster,
    required this.origin,
    required this.declarationDate,
    required this.closedDate,
    required this.statut,
    required this.closingComment,
    required this.cost,
  });

  /// Factory constructor for creating an instance from JSON
  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'],
      userId: json['user_id'],
    //  user: json['user'] != null ? Caisse.fromJson(json['user']) : null,
      boutiqueId: json['boutique_id'],
      boutique: json['boutique'] != null ? BoutiqueModel.fromJson(json['boutique']) : null,
      description: json['description'],
      commentaire: json['commentaire'],
      problemImageBefore: json['problem_image_before'],
      problemImageAfter: json['problem_image_after'],
      jointFileBefore: json['joint_file_before'],
      jointFileAfter: json['joint_file_after'],
      coefId: json['coef_id'],
      coefficient: json['coefficient'] != null ? Coefficient.fromJson(json['coefficient']) : null,
      cluster: json['cluster'],
      origin: json['origin'],
      declarationDate: DateTime.parse(json['declaration_date']),
      closedDate: DateTime.parse(json['closed_date']),
      statut: json['statut'],
      closingComment: json['closing_comment'],
      cost: json['cost'].toDouble(),
    );
  }

  /// Convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
     // 'user': user?.toJson(),
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
      'declaration_date': declarationDate.toIso8601String(),
      'closed_date': closedDate?.toIso8601String(),
      'statut': statut,
      'closing_comment': closingComment,
      'cost': cost,
    };
  }
}