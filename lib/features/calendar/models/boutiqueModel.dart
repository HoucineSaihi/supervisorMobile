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
      'cluster' : cluster
    };
  }
}
