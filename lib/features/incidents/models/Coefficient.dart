class Coefficient {
  final int coefId;
  final String? libelle;
  final double value;

  Coefficient({
    required this.coefId,
    this.libelle,
    required this.value,
  });

  // Factory constructor for creating a Coefficient instance from JSON
  factory Coefficient.fromJson(Map<String, dynamic> json) {
    return Coefficient(
      coefId: json['coef_ID'],
      libelle: json['libelle'],
      value: (json['value'] as num).toDouble(),
    );
  }

  // Method for converting a Coefficient instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'coef_ID': coefId,
      'libelle': libelle,
      'value': value,
    };
  }
}
