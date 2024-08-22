class Group {
  int idGroup;
  String? code;
  String? groupName;
  String? type;

  Group({
    required this.idGroup,
    this.code,
    this.groupName,
    this.type,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      idGroup: json['idGroup'] as int,
      code: json['code'] as String?,
      groupName: json['groupName'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGroup': idGroup,
      'code': code,
      'groupName': groupName,
      'type': type,
    };
  }
}
