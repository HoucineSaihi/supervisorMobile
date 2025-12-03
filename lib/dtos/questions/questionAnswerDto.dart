import '../../features/incidents/models/IncidentCategory.dart';

class questionAnswerDto {
  int? id;
  String? commentaire;
  String? fileName;
  int? actionId;
  int? reponseID;
  int? selectedResponseValue;
  String? jointureFichier;
  IncidentCategory? typeIncident;
  IncidentCategory? originalType;

  questionAnswerDto({this.id,this.commentaire,this.fileName,this.actionId
    ,this.reponseID,this.selectedResponseValue,this.jointureFichier,this.typeIncident,  this.originalType});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentaire':commentaire,
      'fileName':fileName,
      'actionId':actionId,
      'reponseID':reponseID,
      'selectedResponseValue':selectedResponseValue,
      'jointureFichier':jointureFichier,
      'typeIncident': typeIncident?.value,
      'originalType':originalType?.value


    };
  }


}