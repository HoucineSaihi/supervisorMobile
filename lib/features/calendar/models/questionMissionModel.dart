import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/incidentTypeModel.dart';

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
  int? selectedResponseValue;
  double? questionCoefficient;
  bool? incident;
  String? jointureFichier;
  int? coef_ID;
  int? problemId;
  int? incidentTypeId;
  IncidentType? incidentType;
  int? departement_id;

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
    this.reponseID,
    this.selectedResponseValue,
    this.questionCoefficient,
    this.incident,
    this.jointureFichier,
    this.coef_ID,
    this.problemId,
    this.incidentTypeId,
    this.incidentType,
    this.departement_id
  });

  factory QuestionMission.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 QuestionMission.fromJson: Parsing question with ID: ${json['id']}');
      
      // Validate required fields
      if (json['id'] == null) {
        throw Exception('QuestionMission ID is null or missing');
      }
      
      // Log null values for debugging
      final nullFields = <String>[];
      if (json['description'] == null) nullFields.add('description');
      if (json['sousMissionId'] == null) nullFields.add('sousMissionId');
      if (json['reponse'] == null) nullFields.add('reponse');
      if (json['clouture'] == null) nullFields.add('clouture');
      if (json['actionId'] == null) nullFields.add('actionId');
      if (json['actions'] == null) nullFields.add('actions');
      if (json['commentaire'] == null) nullFields.add('commentaire');
      if (json['fileName'] == null) nullFields.add('fileName');
      if (json['choixReponseQuestion'] == null) nullFields.add('choixReponseQuestion');
      if (json['reponseID'] == null) nullFields.add('reponseID');
      if (json['selectedResponseValue'] == null) nullFields.add('selectedResponseValue');
      if (json['questionCoefficient'] == null) nullFields.add('questionCoefficient');
      if (json['incident'] == null) nullFields.add('incident');
      if (json['jointureFichier'] == null) nullFields.add('jointureFichier');
      if (json['coef_ID'] == null) nullFields.add('coef_ID');
      if (json['problemId'] == null) nullFields.add('problemId');
      
      if (nullFields.isNotEmpty) {
        print('⚠️ QuestionMission.fromJson: Null fields detected: ${nullFields.join(', ')}');
      }
      
      // Parse each field individually with detailed logging
      final id = json['id'] as int;
      print('✅ QuestionMission.fromJson: id = $id');
      
      final description = json['description'] as String?;
      print('✅ QuestionMission.fromJson: description = $description');
      
      final sousMissionId = json['sousMissionId'] as int?;
      print('✅ QuestionMission.fromJson: sousMissionId = $sousMissionId');
      
      final reponse = json['reponse'] as String?;
      print('✅ QuestionMission.fromJson: reponse = $reponse');
      
      DateTime? clouture;
      try {
        clouture = json['clouture'] != null ? DateTime.parse(json['clouture']) : null;
        print('✅ QuestionMission.fromJson: clouture = $clouture');
      } catch (e) {
        print('❌ QuestionMission.fromJson: Error parsing clouture: $e');
        clouture = null;
      }
      
      final actionId = json['actionId'] as int?;
      print('✅ QuestionMission.fromJson: actionId = $actionId');
      
      ActionM? actions;
      try {
        actions = json['actions'] != null ? ActionM.fromJson(json['actions']) : null;
        print('✅ QuestionMission.fromJson: actions = ${actions != null ? 'parsed successfully' : 'null'}');
      } catch (e) {
        print('❌ QuestionMission.fromJson: Error parsing actions: $e');
        actions = null;
      }
      
      final commentaire = json['commentaire'] as String?;
      print('✅ QuestionMission.fromJson: commentaire = $commentaire');
      
      final fileName = json['fileName'] as String?;
      print('✅ QuestionMission.fromJson: fileName = $fileName');
      
      ChoixReponseQuestion? choixReponseQuestion;
      try {
        choixReponseQuestion = json['choixReponseQuestion'] != null ? ChoixReponseQuestion.fromJson(json['choixReponseQuestion']) : null;
        print('✅ QuestionMission.fromJson: choixReponseQuestion = ${choixReponseQuestion != null ? 'parsed successfully' : 'null'}');
      } catch (e) {
        print('❌ QuestionMission.fromJson: Error parsing choixReponseQuestion: $e');
        choixReponseQuestion = null;
      }
      
      final reponseID = json['reponseID'] as int?;
      print('✅ QuestionMission.fromJson: reponseID = $reponseID');
      
      final selectedResponseValue = json['selectedResponseValue'] as int?;
      print('✅ QuestionMission.fromJson: selectedResponseValue = $selectedResponseValue');
      
      double? questionCoefficient;
      try {
        questionCoefficient = (json['questionCoefficient'] as num?)?.toDouble();
        print('✅ QuestionMission.fromJson: questionCoefficient = $questionCoefficient');
      } catch (e) {
        print('❌ QuestionMission.fromJson: Error parsing questionCoefficient: $e');
        print('📄 QuestionMission.fromJson: questionCoefficient raw value: ${json['questionCoefficient']} (type: ${json['questionCoefficient'].runtimeType})');
        questionCoefficient = null;
      }
      
      final incident = json['incident'] as bool?;
      print('✅ QuestionMission.fromJson: incident = $incident');
      
      final jointureFichier = json['jointureFichier'] as String?;
      print('✅ QuestionMission.fromJson: jointureFichier = $jointureFichier');
      
      final coef_ID = json['coef_ID'] as int?;
      print('✅ QuestionMission.fromJson: coef_ID = $coef_ID');
      
      final problemId = json['problemId'] as int?;
      print('✅ QuestionMission.fromJson: problemId = $problemId');
      
      final incidentTypeId = json['incidentTypeId'] as int?;
      print('✅ QuestionMission.fromJson: incidentTypeId = $incidentTypeId');
      
      final departement_id = json['departement_id'] as int?;
      print('✅ QuestionMission.fromJson: departement_id = $departement_id');
      
      IncidentType? incidentType;
      try {
        incidentType = json['incidentType'] != null ? IncidentType.fromJson(json['incidentType']) : null;
        print('✅ QuestionMission.fromJson: incidentType = ${incidentType != null ? 'parsed successfully' : 'null'}');
      } catch (e) {
        print('❌ QuestionMission.fromJson: Error parsing incidentType: $e');
        incidentType = null;
      }
      
      print('🎉 QuestionMission.fromJson: All fields parsed successfully, creating QuestionMission object...');
      
      return QuestionMission(
        id: id,
        description: description,
        sousMissionId: sousMissionId,
        reponse: reponse,
        clouture: clouture,
        actionId: actionId,
        actions: actions,
        commentaire: commentaire,
        fileName: fileName,
        choixReponseQuestion: choixReponseQuestion,
        reponseID: reponseID,
        selectedResponseValue: selectedResponseValue,
        questionCoefficient: questionCoefficient,
        incident: incident,
        jointureFichier: jointureFichier,
        coef_ID: coef_ID,
        problemId: problemId,
        incidentTypeId: incidentTypeId,
        incidentType: incidentType,
        departement_id: departement_id,
      );
    } catch (e) {
      print('❌ QuestionMission.fromJson: Error parsing question: $e');
      print('📄 QuestionMission.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'sousMissionId': sousMissionId,
      'reponse': reponse,
      'clouture': clouture?.toIso8601String(),
      'actionId': actionId,
      'actions': actions?.toJson(),
      'commentaire': commentaire,
      'fileName': fileName,
      'choixReponseQuestion': choixReponseQuestion?.toJson(),
      'reponseID': reponseID,
      'selectedResponseValue': selectedResponseValue,
      'questionCoefficient': questionCoefficient,
      'incident': incident,
      'jointureFichier':jointureFichier,
      'coef_ID':coef_ID,
      'problemId':problemId,
      'incidentTypeId': incidentTypeId,
      'incidentType': incidentType?.toJson(),
      'departement_id': departement_id,

    };
  }
}
