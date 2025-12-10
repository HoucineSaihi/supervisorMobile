class Departement {
  final int id;
  final String? code;
  final String? libelle;
  final String? type;
  final List<dynamic>? caisseDepartements;

  Departement({
    required this.id,
    this.code,
    this.libelle,
    this.type,
    this.caisseDepartements,
  });

  factory Departement.fromJson(Map<String, dynamic> json) {
    return Departement(
      id: json['id'] as int,
      code: json['code'] as String?,
      libelle: json['libelle'] as String?,
      type: json['type'] as String?,
      caisseDepartements: json['caisseDepartements'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'libelle': libelle,
      'type': type,
      'caisseDepartements': caisseDepartements,
    };
  }
}

