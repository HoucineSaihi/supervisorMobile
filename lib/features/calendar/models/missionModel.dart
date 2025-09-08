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
  double? progression;

  // New properties for mission status
  bool? isMissed;
  bool? lateStart;

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
    this.progression,
    this.isMissed,
    this.lateStart,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    try {
      // Log the incoming JSON for debugging
      print('🔍 Mission.fromJson: Parsing mission with ID: ${json['id']}');

      // Validate required fields
      if (json['id'] == null) {
        throw Exception('Mission ID is null or missing');
      }

      // Log null values for debugging
      final nullFields = <String>[];
      if (json['libelle'] == null) nullFields.add('libelle');
      if (json['status'] == null) nullFields.add('status');
      if (json['missionCode'] == null) nullFields.add('missionCode');
      if (json['description'] == null) nullFields.add('description');
      if (json['createdAt'] == null) nullFields.add('createdAt');
      if (json['startedAT'] == null) nullFields.add('startedAT');
      if (json['planifiedAt'] == null) nullFields.add('planifiedAt');
      if (json['endedAt'] == null) nullFields.add('endedAt');
      if (json['boutiqueId'] == null) nullFields.add('boutiqueId');
      if (json['boutique'] == null) nullFields.add('boutique');
      if (json['userId'] == null) nullFields.add('userId');
      if (json['activated'] == null) nullFields.add('activated');
      if (json['sousMissions'] == null) nullFields.add('sousMissions');
      if (json['modelReponseQuestionId'] == null) nullFields.add('modelReponseQuestionId');
      if (json['conformite_ID'] == null) nullFields.add('conformite_ID');
      if (json['scoreMax'] == null) nullFields.add('scoreMax');
      if (json['totalQuestion'] == null) nullFields.add('totalQuestion');
      if (json['tauxConformite'] == null) nullFields.add('tauxConformite');
      if (json['progression'] == null) nullFields.add('progression');
      if (json['isMissed'] == null) nullFields.add('isMissed');
      if (json['lateStart'] == null) nullFields.add('lateStart');

      if (nullFields.isNotEmpty) {
        print('⚠️ Mission.fromJson: Null fields detected: ${nullFields.join(', ')}');
      }

      // Detailed field-by-field parsing with error handling
      print('🔍 Mission.fromJson: Starting field-by-field parsing...');

      // Parse each field individually with detailed logging
      final id = json['id'] as int;
      print('✅ Mission.fromJson: id = $id');

      final libelle = json['libelle'] as String?;
      print('✅ Mission.fromJson: libelle = $libelle');

      final status = json['status'] as int?;
      print('✅ Mission.fromJson: status = $status');

      final missionCode = json['missionCode'] as String?;
      print('✅ Mission.fromJson: missionCode = $missionCode');

      final description = json['description'] as String?;
      print('✅ Mission.fromJson: description = $description');

      DateTime? createdAt;
      try {
        createdAt = json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
        print('✅ Mission.fromJson: createdAt = $createdAt');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing createdAt: $e');
        createdAt = null;
      }

      DateTime? startedAT;
      try {
        startedAT = json['startedAT'] != null ? DateTime.parse(json['startedAT']) : null;
        print('✅ Mission.fromJson: startedAT = $startedAT');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing startedAT: $e');
        startedAT = null;
      }

      DateTime? planifiedAt;
      try {
        planifiedAt = json['planifiedAt'] != null ? DateTime.parse(json['planifiedAt']) : null;
        print('✅ Mission.fromJson: planifiedAt = $planifiedAt');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing planifiedAt: $e');
        planifiedAt = null;
      }

      DateTime? endedAt;
      try {
        endedAt = json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null;
        print('✅ Mission.fromJson: endedAt = $endedAt');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing endedAt: $e');
        endedAt = null;
      }

      final boutiqueId = json['boutiqueId'] as int?;
      print('✅ Mission.fromJson: boutiqueId = $boutiqueId');

      BoutiqueModel? boutique;
      try {
        boutique = json['boutique'] != null ? BoutiqueModel.fromJson(json['boutique']) : null;
        print('✅ Mission.fromJson: boutique = ${boutique != null ? 'parsed successfully' : 'null'}');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing boutique: $e');
        boutique = null;
      }

      final userId = json['userId'] as int?;
      print('✅ Mission.fromJson: userId = $userId');

      final activated = json['activated'] as bool?;
      print('✅ Mission.fromJson: activated = $activated');

      List<SousMission>? sousMissions;
      try {
        sousMissions = json['sousMissions'] != null
            ? (json['sousMissions'] as List).map((i) => SousMission.fromJson(i)).toList()
            : null;
        print('✅ Mission.fromJson: sousMissions = ${sousMissions?.length ?? 0} items');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing sousMissions: $e');
        sousMissions = null;
      }

      final modelReponseQuestionId = json['modelReponseQuestionId'] as int?;
      print('✅ Mission.fromJson: modelReponseQuestionId = $modelReponseQuestionId');

      final conformite_ID = json['conformite_ID'] as int?;
      print('✅ Mission.fromJson: conformite_ID = $conformite_ID');

      double? scoreMax;
      try {
        scoreMax = json['scoreMax'] != null ? (json['scoreMax'] as num).toDouble() : null;
        print('✅ Mission.fromJson: scoreMax = $scoreMax');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing scoreMax: $e');
        print('📄 Mission.fromJson: scoreMax raw value: ${json['scoreMax']} (type: ${json['scoreMax'].runtimeType})');
        scoreMax = null;
      }

      final totalQuestion = json['totalQuestion'] as int?;
      print('✅ Mission.fromJson: totalQuestion = $totalQuestion');

      double? tauxConformite;
      try {
        tauxConformite = json['tauxConformite'] != null ? (json['tauxConformite'] as num).toDouble() : null;
        print('✅ Mission.fromJson: tauxConformite = $tauxConformite');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing tauxConformite: $e');
        print('📄 Mission.fromJson: tauxConformite raw value: ${json['tauxConformite']} (type: ${json['tauxConformite'].runtimeType})');
        tauxConformite = null;
      }

      double? progression;
      try {
        progression = json['progression'] != null ? (json['progression'] as num).toDouble() : null;
        print('✅ Mission.fromJson: progression = $progression');
      } catch (e) {
        print('❌ Mission.fromJson: Error parsing progression: $e');
        print('📄 Mission.fromJson: progression raw value: ${json['progression']} (type: ${json['progression'].runtimeType})');
        progression = null;
      }

      final isMissed = json['isMissed'] as bool?;
      print('✅ Mission.fromJson: isMissed = $isMissed');

      final lateStart = json['lateStart'] as bool?;
      print('✅ Mission.fromJson: lateStart = $lateStart');

      print('🎉 Mission.fromJson: All fields parsed successfully, creating Mission object...');

      return Mission(
        id: id,
        libelle: libelle,
        status: status,
        missionCode: missionCode,
        description: description,
        createdAt: createdAt,
        startedAT: startedAT,
        planifiedAt: planifiedAt,
        endedAt: endedAt,
        boutiqueId: boutiqueId,
        boutique: boutique,
        userId: userId,
        activated: activated,
        sousMissions: sousMissions,
        modelReponseQuestionId: modelReponseQuestionId,
        conformite_ID: conformite_ID,
        scoreMax: scoreMax,
        totalQuestion: totalQuestion,
        tauxConformite: tauxConformite,
        progression: progression,
        isMissed: isMissed,
        lateStart: lateStart,
      );
    } catch (e) {
      print('❌ Mission.fromJson: Error parsing mission: $e');
      print('📄 Mission.fromJson: JSON data: $json');
      rethrow; // Re-throw the exception to maintain the original error handling
    }
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
      'progression':progression,
      'isMissed': isMissed,
      'lateStart': lateStart,
    };
  }
}