class Group {
  String? code;
  int? idGroup;
  String? groupName;
  String? type;

  Group({
    this.code,
    this.idGroup,
    this.groupName,
    this.type,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      code: json['code'] as String?,
      idGroup: json['idGroup'] as int?,
      groupName: json['groupName'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'idGroup': idGroup,
      'groupName': groupName,
      'type': type,
    };
  }
}
