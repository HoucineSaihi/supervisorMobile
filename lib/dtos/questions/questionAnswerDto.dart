class questionAnswerDto {
  int? id;
  String? commentaire;
  String? fileName;
  int? actionId;
  int? reponseID;
  int? selectedResponseValue;
  String? jointureFichier;
  int? IncidentTypeId;
  double? latitude;
  double? longitude;
  int? departementId;

  questionAnswerDto({this.id,this.commentaire,this.fileName,this.actionId
    ,this.reponseID,this.selectedResponseValue,this.jointureFichier,this.IncidentTypeId,this.latitude,this.longitude,this.departementId});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentaire':commentaire,
      'fileName':fileName,
      'actionId':actionId,
      'reponseID':reponseID,
      'selectedResponseValue':selectedResponseValue,
      'jointureFichier':jointureFichier,
      'IncidentTypeId': IncidentTypeId,
      'latitude': latitude,
      'longitude': longitude,
      'departementId': departementId,
    };
  }


}