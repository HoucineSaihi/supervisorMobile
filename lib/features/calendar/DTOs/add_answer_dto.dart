class AddAnswerDto {
  int missionId;
  int questionId;
  String? commentaire;
  String? fileName;
  int? actionId;
  int? reponseId;
  String? jointureFichier;

  AddAnswerDto({
    required this.missionId,
    required this.questionId,
    this.commentaire,
    this.fileName,
    this.actionId,
    this.reponseId,
    this.jointureFichier,
  });

  // Convert from JSON
  factory AddAnswerDto.fromJson(Map<String, dynamic> json) {
    return AddAnswerDto(
      missionId: json['mission_id'] ?? 0,
      questionId: json['question_id'] ?? 0,
      commentaire: json['Commentaire'],
      fileName: json['fileName'],
      actionId: json['ActionId'],
      reponseId: json['reponseID'],
      jointureFichier: json['jointureFichier'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'mission_id': missionId,
      'question_id': questionId,
      'Commentaire': commentaire,
      'fileName': fileName,
      'ActionId': actionId,
      'reponseID': reponseId,
      'jointureFichier': jointureFichier,
    };
  }
}
