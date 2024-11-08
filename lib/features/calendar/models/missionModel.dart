import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/modelReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/sousMissionModel.dart';

class Mission {
  int id;
  String? libelle;
  int? status;
  String? missionCode;
  String? description;
  DateTime? createdAt;
  DateTime? startedAT;
  DateTime? planifiedAt;
  DateTime? endedAt;
  int? boutiqueId;
  BoutiqueModel? boutique;
  int? userId;
  bool? activated;
  List<SousMission>? sousMissions;
  int? modelReponseQuestionId;
  int? conformite_ID;

  double? scoreMax;
  int? totalQuestion;
  double? tauxConformite;

  Mission({
    required this.id,
    this.libelle,
    this.status,
    this.missionCode,
    this.description,
    this.createdAt,
    this.startedAT,
    this.planifiedAt,
    this.endedAt,
    this.boutiqueId,
    this.boutique,
    this.userId,
    this.activated,
    this.sousMissions,
    this.modelReponseQuestionId,
    this.conformite_ID,
    this.scoreMax,
    this.totalQuestion,
    this.tauxConformite,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as int,
      libelle: json['libelle'] as String?,
      status: json['status'] as int?,
      missionCode: json['missionCode'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      startedAT: json['startedAT'] != null ? DateTime.parse(json['startedAT']) : null,
      planifiedAt: json['planifiedAt'] != null ? DateTime.parse(json['planifiedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      boutiqueId: json['boutiqueId'] as int?,
      boutique: json['boutique'] != null ? BoutiqueModel.fromJson(json['boutique']) : null,
      userId: json['userId'] as int?,
      activated: json['activated'] as bool?,
      sousMissions: json['sousMissions'] != null
          ? (json['sousMissions'] as List).map((i) => SousMission.fromJson(i)).toList()
          : null,
      modelReponseQuestionId: json['modelReponseQuestionId'] as int?,
      conformite_ID: json['conformite_ID'] as int?,
      scoreMax: (json['scoreMax'] as num?)?.toDouble(),
      totalQuestion: json['totalQuestion'] as int?,
      tauxConformite: (json['tauxConformite'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'status': status,
      'missionCode': missionCode,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'startedAT': startedAT?.toIso8601String(),
      'planifiedAt': planifiedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'boutiqueId': boutiqueId,
      'boutique': boutique?.toJson(),
      'userId': userId,
      'activated': activated,
      'sousMissions': sousMissions?.map((e) => e.toJson()).toList(),
      'modelReponseQuestionId': modelReponseQuestionId,
      'conformite_ID': conformite_ID,
      'scoreMax': scoreMax,
      'totalQuestion': totalQuestion,
      'tauxConformite': tauxConformite,
    };
  }
}
