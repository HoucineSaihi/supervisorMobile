class IncidentType {
  int id;
  String? libelle;

  IncidentType({
    required this.id,
    this.libelle,
  });

  factory IncidentType.fromJson(Map<String, dynamic> json) {
    return IncidentType(
      id: json['id'] as int,
      libelle: json['libelle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }
}

