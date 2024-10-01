class BoutiqueModel {
  int id;
  String? code;
  String? libelle;
  String? city;
  String? region;
  String? country;
  String? adress;
  DateTime? dateCreation;

  BoutiqueModel({
    required this.id,
    this.code,
    this.libelle,
    this.city,
    this.region,
    this.country,
    this.adress,
    this.dateCreation,
  });

  // Factory method to create an instance from JSON
  factory BoutiqueModel.fromJson(Map<String, dynamic> json) {
    return BoutiqueModel(
      id: json['id'] as int,
      code: json['code'] as String?,
      libelle: json['libelle'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      adress: json['adress'] as String?,
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'] as String)
          : null,
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'libelle': libelle,
      'city': city,
      'region': region,
      'country': country,
      'adress': adress,
      'dateCreation': dateCreation?.toIso8601String(),
    };
  }

  // Copy method to create a new instance with modified values
  BoutiqueModel copyWith({
    int? id,
    String? code,
    String? libelle,
    String? city,
    String? region,
    String? country,
    String? adress,
    DateTime? dateCreation,
  }) {
    return BoutiqueModel(
      id: id ?? this.id,
      code: code ?? this.code,
      libelle: libelle ?? this.libelle,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      adress: adress ?? this.adress,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
