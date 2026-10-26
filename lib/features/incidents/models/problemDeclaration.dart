/// One declaration of an incident (first one or re-declaration from a later
/// checklist), with all the data of the answer that declared it.
class ProblemDeclaration {
  final int id;
  final bool isInitial;
  final DateTime? declaredAt;
  final String? declaredByName;

  final String? missionCode;
  final String? missionLibelle;
  final DateTime? checklistPlanifiedDate;
  final String? categoryCode;
  final String? categoryLibelle;

  final int missionQuestionId;
  final String? questionDescription;
  final String? responseLibelle;
  final int? responseValue;
  final String? responseColor;
  final String? commentaire;
  final String? fileName; // photo
  final String? jointureFichier; // attachment
  final String? actionDescription;
  final String? actionResponsable;
  final double? latitude;
  final double? longitude;

  final String? departementLibelle;
  final String? incidentTypeLibelle;

  ProblemDeclaration({
    required this.id,
    required this.isInitial,
    required this.missionQuestionId,
    this.declaredAt,
    this.declaredByName,
    this.missionCode,
    this.missionLibelle,
    this.checklistPlanifiedDate,
    this.categoryCode,
    this.categoryLibelle,
    this.questionDescription,
    this.responseLibelle,
    this.responseValue,
    this.responseColor,
    this.commentaire,
    this.fileName,
    this.jointureFichier,
    this.actionDescription,
    this.actionResponsable,
    this.latitude,
    this.longitude,
    this.departementLibelle,
    this.incidentTypeLibelle,
  });

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory ProblemDeclaration.fromJson(Map<String, dynamic> json) {
    return ProblemDeclaration(
      id: (json['id'] as num).toInt(),
      isInitial: json['isInitial'] as bool? ?? false,
      missionQuestionId: (json['missionQuestionId'] as num?)?.toInt() ?? 0,
      declaredAt: _date(json['declaredAt']),
      declaredByName: json['declaredByName'] as String?,
      missionCode: json['missionCode'] as String?,
      missionLibelle: json['missionLibelle'] as String?,
      checklistPlanifiedDate: _date(json['checklistPlanifiedDate']),
      categoryCode: json['categoryCode'] as String?,
      categoryLibelle: json['categoryLibelle'] as String?,
      questionDescription: json['questionDescription'] as String?,
      responseLibelle: json['responseLibelle'] as String?,
      responseValue: (json['responseValue'] as num?)?.toInt(),
      responseColor: json['responseColor'] as String?,
      commentaire: json['commentaire'] as String?,
      fileName: json['fileName'] as String?,
      jointureFichier: json['jointureFichier'] as String?,
      actionDescription: json['actionDescription'] as String?,
      actionResponsable: json['actionResponsable'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      departementLibelle: json['departementLibelle'] as String?,
      incidentTypeLibelle: json['incidentTypeLibelle'] as String?,
    );
  }
}

/// Open incident already declared for the same question (shown before answering).
class OpenIncident {
  final int problemId;
  final DateTime? declarationDate;
  final int? status;
  final int? statusType;
  final int declarationsCount;
  final bool declaredByThisQuestion;

  OpenIncident({
    required this.problemId,
    this.declarationDate,
    this.status,
    this.statusType,
    this.declarationsCount = 1,
    this.declaredByThisQuestion = false,
  });

  factory OpenIncident.fromJson(Map<String, dynamic> json) {
    return OpenIncident(
      problemId: (json['problemId'] as num).toInt(),
      declarationDate: json['declarationDate'] is String
          ? DateTime.tryParse(json['declarationDate'])
          : null,
      status: (json['status'] as num?)?.toInt(),
      statusType: (json['statusType'] as num?)?.toInt(),
      declarationsCount: (json['declarationsCount'] as num?)?.toInt() ?? 1,
      declaredByThisQuestion: json['declaredByThisQuestion'] as bool? ?? false,
    );
  }
}
