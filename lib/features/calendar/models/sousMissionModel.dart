import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';

import '../../incidents/models/IncidentCategory.dart';

class SousMission {
  int? id;
  String? libelle;
  String? code;
  String? description;
  DateTime? dateCreation;
  int? missionId;
  List<QuestionMission>? missionQuestions;

  int? sommeValeurPositive;
  double? sommeCalculPoint;
  double? scoreMax;
  double? tauxConformiteCategorie;
  int? nombreQuestion;
  int? coefficient_ID;
  double? selectedCoefficient;
  IncidentCategory? typeIncident;

  SousMission({
    this.id,
    this.libelle,
    this.code,
    this.description,
    this.dateCreation,
    this.missionId,
    this.missionQuestions,
    this.sommeValeurPositive,
    this.sommeCalculPoint,
    this.scoreMax,
    this.tauxConformiteCategorie,
    this.nombreQuestion,
    this.coefficient_ID,
    this.selectedCoefficient,
    this.typeIncident
  });

  factory SousMission.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 SousMission.fromJson: Parsing sous-mission with ID: ${json['id']}');
      
      // Log null values for debugging
      final nullFields = <String>[];
      if (json['id'] == null) nullFields.add('id');
      if (json['libelle'] == null) nullFields.add('libelle');
      if (json['code'] == null) nullFields.add('code');
      if (json['description'] == null) nullFields.add('description');
      if (json['dateCreation'] == null) nullFields.add('dateCreation');
      if (json['missionId'] == null) nullFields.add('missionId');
      if (json['missionQuestions'] == null) nullFields.add('missionQuestions');
      if (json['sommeValeurPositive'] == null) nullFields.add('sommeValeurPositive');
      if (json['sommeCalculPoint'] == null) nullFields.add('sommeCalculPoint');
      if (json['scoreMax'] == null) nullFields.add('scoreMax');
      if (json['tauxConformiteCategorie'] == null) nullFields.add('tauxConformiteCategorie');
      if (json['nombreQuestion'] == null) nullFields.add('nombreQuestion');
      if (json['coefficient_ID'] == null) nullFields.add('coefficient_ID');
      if (json['selectedCoefficient'] == null) nullFields.add('selectedCoefficient');
      if (json['typeIncident'] == null) nullFields.add('typeIncident');
      
      if (nullFields.isNotEmpty) {
        print('⚠️ SousMission.fromJson: Null fields detected: ${nullFields.join(', ')}');
      }
      
      // Parse each field individually with detailed logging
      final id = json['id'] as int?;
      print('✅ SousMission.fromJson: id = $id');
      
      final libelle = json['libelle'] as String?;
      print('✅ SousMission.fromJson: libelle = $libelle');
      
      final code = json['code'] as String?;
      print('✅ SousMission.fromJson: code = $code');
      
      final description = json['description'] as String?;
      print('✅ SousMission.fromJson: description = $description');
      
      DateTime? dateCreation;
      try {
        dateCreation = json['dateCreation'] != null ? DateTime.parse(json['dateCreation']) : null;
        print('✅ SousMission.fromJson: dateCreation = $dateCreation');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing dateCreation: $e');
        dateCreation = null;
      }
      
      final missionId = json['missionId'] as int?;
      print('✅ SousMission.fromJson: missionId = $missionId');
      
      List<QuestionMission>? missionQuestions;
      try {
        missionQuestions = json['missionQuestions'] != null
            ? (json['missionQuestions'] as List).map((i) => QuestionMission.fromJson(i)).toList()
            : null;
        print('✅ SousMission.fromJson: missionQuestions = ${missionQuestions?.length ?? 0} items');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing missionQuestions: $e');
        missionQuestions = null;
      }
      
      final sommeValeurPositive = json['sommeValeurPositive'] as int?;
      print('✅ SousMission.fromJson: sommeValeurPositive = $sommeValeurPositive');
      
      double? sommeCalculPoint;
      try {
        sommeCalculPoint = (json['sommeCalculPoint'] as num?)?.toDouble();
        print('✅ SousMission.fromJson: sommeCalculPoint = $sommeCalculPoint');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing sommeCalculPoint: $e');
        print('📄 SousMission.fromJson: sommeCalculPoint raw value: ${json['sommeCalculPoint']} (type: ${json['sommeCalculPoint'].runtimeType})');
        sommeCalculPoint = null;
      }
      
      double? scoreMax;
      try {
        scoreMax = (json['scoreMax'] as num?)?.toDouble();
        print('✅ SousMission.fromJson: scoreMax = $scoreMax');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing scoreMax: $e');
        print('📄 SousMission.fromJson: scoreMax raw value: ${json['scoreMax']} (type: ${json['scoreMax'].runtimeType})');
        scoreMax = null;
      }
      
      double? tauxConformiteCategorie;
      try {
        tauxConformiteCategorie = (json['tauxConformiteCategorie'] as num?)?.toDouble();
        print('✅ SousMission.fromJson: tauxConformiteCategorie = $tauxConformiteCategorie');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing tauxConformiteCategorie: $e');
        print('📄 SousMission.fromJson: tauxConformiteCategorie raw value: ${json['tauxConformiteCategorie']} (type: ${json['tauxConformiteCategorie'].runtimeType})');
        tauxConformiteCategorie = null;
      }
      
      final nombreQuestion = json['nombreQuestion'] as int?;
      print('✅ SousMission.fromJson: nombreQuestion = $nombreQuestion');
      
      final coefficient_ID = json['coefficient_ID'] as int?;
      print('✅ SousMission.fromJson: coefficient_ID = $coefficient_ID');
      
      double? selectedCoefficient;
      try {
        selectedCoefficient = (json['selectedCoefficient'] as num?)?.toDouble();
        print('✅ SousMission.fromJson: selectedCoefficient = $selectedCoefficient');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing selectedCoefficient: $e');
        print('📄 SousMission.fromJson: selectedCoefficient raw value: ${json['selectedCoefficient']} (type: ${json['selectedCoefficient'].runtimeType})');
        selectedCoefficient = null;
      }
      
      IncidentCategory? typeIncident;
      try {
        typeIncident = (json['typeIncident'] != null)
            ? IncidentCategoryExtension.fromString(json['typeIncident'])
            : IncidentCategory.all;
        print('✅ SousMission.fromJson: typeIncident = $typeIncident');
      } catch (e) {
        print('❌ SousMission.fromJson: Error parsing typeIncident: $e');
        typeIncident = IncidentCategory.all;
      }
      
      print('🎉 SousMission.fromJson: All fields parsed successfully, creating SousMission object...');
      
      return SousMission(
        id: id,
        libelle: libelle,
        code: code,
        description: description,
        dateCreation: dateCreation,
        missionId: missionId,
        missionQuestions: missionQuestions,
        sommeValeurPositive: sommeValeurPositive,
        sommeCalculPoint: sommeCalculPoint,
        scoreMax: scoreMax,
        tauxConformiteCategorie: tauxConformiteCategorie,
        nombreQuestion: nombreQuestion,
        coefficient_ID: coefficient_ID,
        selectedCoefficient: selectedCoefficient,
        typeIncident: typeIncident,
      );
    } catch (e) {
      print('❌ SousMission.fromJson: Error parsing sous-mission: $e');
      print('📄 SousMission.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'code': code,
      'description': description,
      'dateCreation': dateCreation?.toIso8601String(),
      'missionId': missionId,
      'missionQuestions': missionQuestions?.map((q) => q.toJson()).toList(),
      'sommeValeurPositive': sommeValeurPositive,
      'sommeCalculPoint': sommeCalculPoint,
      'scoreMax': scoreMax,
      'tauxConformiteCategorie': tauxConformiteCategorie,
      'nombreQuestion':nombreQuestion,
      'coefficient_ID':coefficient_ID,
      'selectedCoefficient':selectedCoefficient,
      'typeIncident': typeIncident?.value,

    };
  }
}