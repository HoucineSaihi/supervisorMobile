class Role {
  int idRole;
  String? code;
  String? libelle;

  Role({
    required this.idRole,
    this.code,
    this.libelle,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      idRole: json['idRole'] as int,
      code: json['code'] as String?,
      libelle: json['libelle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idRole': idRole,
      'code': code,
      'libelle': libelle,
    };
  }
}
