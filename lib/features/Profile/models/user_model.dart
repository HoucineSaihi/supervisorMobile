import 'package:supervisormobile/features/Profile/models/group_model.dart';
import 'package:supervisormobile/features/Profile/models/role_model.dart';

class UserModel {
  int id;
  String? nom;
  String? username;
  String? passwd;
  String? fax;
  String? tel;
  int? codePostal;
  String? img;
  int? idBoutique;
  String? libBoutique;
  List<Group>? groups;
  List<int>? grpsId;
  int? roleId;
  Role? role;

  UserModel({
    required this.id,
    this.nom,
    this.username,
    this.passwd,
    this.fax,
    this.tel,
    this.codePostal,
    this.img,
    this.idBoutique,
    this.libBoutique,
    this.groups,
    this.grpsId,
    this.roleId,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nom: json['nom'] as String?,
      username: json['username'] as String?,
      passwd: json['passwd'] as String?,
      fax: json['fax'] as String?,
      tel: json['tel'] as String?,
      codePostal: json['codePostal'] as int?,
      img: json['img'] as String?,
      idBoutique: json['idBoutique'] as int?,
      libBoutique: json['libBoutique'] as String?,
      groups: (json['groups'] as List<dynamic>?)
          ?.map((groupJson) => Group.fromJson(groupJson as Map<String, dynamic>))
          .toList(),
      grpsId: (json['grpsId'] as List<dynamic>?)?.map((id) => id as int).toList(),
      roleId: json['roleId'] as int?,
      role: json['role'] != null ? Role.fromJson(json['role'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'username': username,
      'passwd': passwd,
      'fax': fax,
      'tel': tel,
      'codePostal': codePostal,
      'img': img,
      'idBoutique': idBoutique,
      'libBoutique': libBoutique,
      'grpsId': grpsId,
      'roleId': roleId,
    };
  }

  UserModel copyWith({
    int? id,
    String? nom,
    String? username,
    String? passwd,
    String? fax,
    String? tel,
    int? codePostal,
    String? img,
    int? idBoutique,
    String? libBoutique,
    List<Group>? groups,
    List<int>? grpsId,
    int? roleId,
    Role? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      username: username ?? this.username,
      passwd: passwd ?? this.passwd,
      fax: fax ?? this.fax,
      tel: tel ?? this.tel,
      codePostal: codePostal ?? this.codePostal,
      img: img ?? this.img,
      idBoutique: idBoutique ?? this.idBoutique,
      libBoutique: libBoutique ?? this.libBoutique,
      groups: groups ?? this.groups,
      grpsId: grpsId ?? this.grpsId,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
    );
  }
}
