import 'package:supervisormobile/features/calendar/models/modelReponseQuestion.dart';

class ChoixReponseQuestion {
  int id;
  int valeur;
  String? libelle;
  String? description;
  String? color; // Added color attribute
  int idModele;
  bool incident; // Added incident attribute
  ModeleReponseQuestion? modeleReponseQuestion;

  ChoixReponseQuestion({
    required this.id,
    required this.valeur,
    this.libelle,
    this.description,
    this.color, // Initialize color
    required this.idModele,
    required this.incident, // Initialize incident
    this.modeleReponseQuestion,
  });

  // Factory method to create ChoixReponseQuestion from JSON
  factory ChoixReponseQuestion.fromJson(Map<String, dynamic> json) {
    return ChoixReponseQuestion(
      id: json['id'] as int,
      valeur: json['valeur'] as int,
      libelle: json['libelle'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?, // Extract color from JSON
      idModele: json['idModele'] as int,
      incident: json['incident'] as bool, // Extract incident from JSON
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
      'color': color, // Include color in JSON
      'idModele': idModele,
      'incident': incident, // Include incident in JSON
      'modeleReponseQuestion': modeleReponseQuestion?.toJson(),
    };
  }
}
