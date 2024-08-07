class ActionM {
  int id;
  String? code;
  String description;
  String? mail;
  String? responsable;

  ActionM({
    required this.id,
    this.code,
    required this.description,
    this.mail,
    this.responsable,
  });

  factory ActionM.fromJson(Map<String, dynamic> json) {
    return ActionM(
      id: json['id'] as int,
      code: json['code'] as String?,
      description: json['description'] as String,
      mail: json['mail'] as String?,
      responsable: json['responsable'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'mail': mail,
      'responsable': responsable,
    };
  }

  @override
  String toString() {
    return description;
  }

  @override
  bool filter(String query) {
    return description.toLowerCase().contains(query.toLowerCase());
  }
}
