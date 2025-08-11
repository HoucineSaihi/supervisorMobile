import 'package:supervisormobile/features/calendar/models/groupModel.dart';

class BoutiqueModel {
  int id;
  String? code;
  String? libelle;
  String? city;
  String? region;
  String? country;
  String? adress;
  DateTime? datecreation;
  String? adresseIp;
  String? storeId;
  String? warehouseId;
  String? dbId;
  String? env;
  String? usernameCegid;
  String? passwordCegid;
  int? groupId;
  Group? group;
  int? cluster;

  BoutiqueModel({
    required this.id,
    this.code,
    this.libelle,
    this.city,
    this.region,
    this.country,
    this.adress,
    this.datecreation,
    this.adresseIp,
    this.storeId,
    this.warehouseId,
    this.dbId,
    this.env,
    this.usernameCegid,
    this.passwordCegid,
    this.groupId,
    this.group,
    this.cluster
  });

  factory BoutiqueModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 BoutiqueModel.fromJson: Parsing boutique with ID: ${json['id']}');
      
      // Validate required fields
      if (json['id'] == null) {
        throw Exception('BoutiqueModel ID is null or missing');
      }
      
      // Log null values for debugging
      final nullFields = <String>[];
      if (json['code'] == null) nullFields.add('code');
      if (json['libelle'] == null) nullFields.add('libelle');
      if (json['city'] == null) nullFields.add('city');
      if (json['region'] == null) nullFields.add('region');
      if (json['country'] == null) nullFields.add('country');
      if (json['adress'] == null) nullFields.add('adress');
      if (json['datecreation'] == null) nullFields.add('datecreation');
      if (json['adresseIp'] == null) nullFields.add('adresseIp');
      if (json['storeId'] == null) nullFields.add('storeId');
      if (json['warehouseId'] == null) nullFields.add('warehouseId');
      if (json['dbId'] == null) nullFields.add('dbId');
      if (json['env'] == null) nullFields.add('env');
      if (json['usernameCegid'] == null) nullFields.add('usernameCegid');
      if (json['passwordCegid'] == null) nullFields.add('passwordCegid');
      if (json['groupId'] == null) nullFields.add('groupId');
      if (json['group'] == null) nullFields.add('group');
      if (json['cluster'] == null) nullFields.add('cluster');
      
      if (nullFields.isNotEmpty) {
        print('⚠️ BoutiqueModel.fromJson: Null fields detected: ${nullFields.join(', ')}');
      }
      
      // Parse each field individually with detailed logging
      final id = json['id'] as int;
      print('✅ BoutiqueModel.fromJson: id = $id');
      
      final code = json['code'] as String?;
      print('✅ BoutiqueModel.fromJson: code = $code');
      
      final libelle = json['libelle'] as String?;
      print('✅ BoutiqueModel.fromJson: libelle = $libelle');
      
      final city = json['city'] as String?;
      print('✅ BoutiqueModel.fromJson: city = $city');
      
      final region = json['region'] as String?;
      print('✅ BoutiqueModel.fromJson: region = $region');
      
      final country = json['country'] as String?;
      print('✅ BoutiqueModel.fromJson: country = $country');
      
      final adress = json['adress'] as String?;
      print('✅ BoutiqueModel.fromJson: adress = $adress');
      
      DateTime? datecreation;
      try {
        datecreation = json['datecreation'] != null ? DateTime.parse(json['datecreation']) : null;
        print('✅ BoutiqueModel.fromJson: datecreation = $datecreation');
      } catch (e) {
        print('❌ BoutiqueModel.fromJson: Error parsing datecreation: $e');
        datecreation = null;
      }
      
      final adresseIp = json['adresseIp'] as String?;
      print('✅ BoutiqueModel.fromJson: adresseIp = $adresseIp');
      
      final storeId = json['storeId'] as String?;
      print('✅ BoutiqueModel.fromJson: storeId = $storeId');
      
      final warehouseId = json['warehouseId'] as String?;
      print('✅ BoutiqueModel.fromJson: warehouseId = $warehouseId');
      
      final dbId = json['dbId'] as String?;
      print('✅ BoutiqueModel.fromJson: dbId = $dbId');
      
      final env = json['env'] as String?;
      print('✅ BoutiqueModel.fromJson: env = $env');
      
      final usernameCegid = json['usernameCegid'] as String?;
      print('✅ BoutiqueModel.fromJson: usernameCegid = $usernameCegid');
      
      final passwordCegid = json['passwordCegid'] as String?;
      print('✅ BoutiqueModel.fromJson: passwordCegid = $passwordCegid');
      
      final groupId = json['groupId'] as int?;
      print('✅ BoutiqueModel.fromJson: groupId = $groupId');
      
      Group? group;
      try {
        group = json['group'] != null ? Group.fromJson(json['group']) : null;
        print('✅ BoutiqueModel.fromJson: group = ${group != null ? 'parsed successfully' : 'null'}');
      } catch (e) {
        print('❌ BoutiqueModel.fromJson: Error parsing group: $e');
        group = null;
      }
      
      final cluster = json['cluster'] as int?; // Fixed: now nullable
      print('✅ BoutiqueModel.fromJson: cluster = $cluster');
      
      print('🎉 BoutiqueModel.fromJson: All fields parsed successfully, creating BoutiqueModel object...');
      
      return BoutiqueModel(
        id: id,
        code: code,
        libelle: libelle,
        city: city,
        region: region,
        country: country,
        adress: adress,
        datecreation: datecreation,
        adresseIp: adresseIp,
        storeId: storeId,
        warehouseId: warehouseId,
        dbId: dbId,
        env: env,
        usernameCegid: usernameCegid,
        passwordCegid: passwordCegid,
        groupId: groupId,
        group: group,
        cluster: cluster,
      );
    } catch (e) {
      print('❌ BoutiqueModel.fromJson: Error parsing boutique: $e');
      print('📄 BoutiqueModel.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'libelle': libelle,
      'city': city,
      'region': region,
      'country': country,
      'adress': adress,
      'datecreation': datecreation?.toIso8601String(),
      'adresseIp': adresseIp,
      'storeId': storeId,
      'warehouseId': warehouseId,
      'dbId': dbId,
      'env': env,
      'usernameCegid': usernameCegid,
      'passwordCegid': passwordCegid,
      'groupId': groupId,
      'group': group?.toJson(),
      'cluster' : cluster
    };
  }
}
