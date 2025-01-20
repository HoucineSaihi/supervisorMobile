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
    return BoutiqueModel(
      id: json['id'] as int,
      code: json['code'] as String?,
      libelle: json['libelle'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      adress: json['adress'] as String?,
      datecreation: json['datecreation'] != null ? DateTime.parse(json['datecreation']) : null,
      adresseIp: json['adresseIp'] as String?,
      storeId: json['storeId'] as String?,
      warehouseId: json['warehouseId'] as String?,
      dbId: json['dbId'] as String?,
      env: json['env'] as String?,
      usernameCegid: json['usernameCegid'] as String?,
      passwordCegid: json['passwordCegid'] as String?,
      groupId: json['groupId'] as int?,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      cluster: json['cluster'] as int
    );
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
