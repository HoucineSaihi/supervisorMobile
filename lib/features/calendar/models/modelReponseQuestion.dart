import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';

class ModeleReponseQuestion {
  int id;
  String? libelle;
  String? description;
  List<ChoixReponseQuestion>? choixReponseQuestions;

  ModeleReponseQuestion({
    required this.id,
    this.libelle,
    this.description,
    this.choixReponseQuestions,
  });

  // Factory method to create ModeleReponseQuestion from JSON
  factory ModeleReponseQuestion.fromJson(Map<String, dynamic> json) {
    return ModeleReponseQuestion(
      id: json['id'] as int,
      libelle: json['libelle'] as String?,
      description: json['description'] as String?,
      choixReponseQuestions: json['choixReponseQuestions'] != null
          ? (json['choixReponseQuestions'] as List)
          .map((item) => ChoixReponseQuestion.fromJson(item))
          .toList()
          : null,
    );
  }

  // Method to convert ModeleReponseQuestion instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'description': description,
      'choixReponseQuestions':
      choixReponseQuestions?.map((e) => e.toJson()).toList(),
    };
  }
}
