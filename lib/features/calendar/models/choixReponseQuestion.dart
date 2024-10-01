import 'package:supervisormobile/features/calendar/models/modelReponseQuestion.dart';

class ChoixReponseQuestion {
  int id;
  int valeur;
  String? libelle;
  String? description;
  int idModele;
  ModeleReponseQuestion? modeleReponseQuestion;

  ChoixReponseQuestion({
    required this.id,
    required this.valeur,
    this.libelle,
    this.description,
    required this.idModele,
    this.modeleReponseQuestion,
  });

  // Factory method to create ChoixReponseQuestion from JSON
  factory ChoixReponseQuestion.fromJson(Map<String, dynamic> json) {
    return ChoixReponseQuestion(
      id: json['id'] as int,
      valeur: json['valeur'] as int,
      libelle: json['libelle'] as String?,
      description: json['description'] as String?,
      idModele: json['idModele'] as int,
      modeleReponseQuestion: json['modeleReponseQuestion'] != null
          ? ModeleReponseQuestion.fromJson(json['modeleReponseQuestion'])
          : null,
    );
  }

  // Method to convert ChoixReponseQuestion instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valeur': valeur,
      'libelle': libelle,
      'description': description,
      'idModele': idModele,
      'modeleReponseQuestion': modeleReponseQuestion?.toJson(),
    };
  }
}
