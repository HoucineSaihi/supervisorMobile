import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';

/// What must be provided with an answer, set in the web "Paramètres" page.
/// Same values as the backend: 0 none, 1 comment, 2 photo, 3 comment + photo.
class JustificationRules {
  static const int none = 0;
  static const int comment = 1;
  static const int photo = 2;
  static const int commentAndPhoto = 3;

  final int incident;
  final int notApplicable;

  const JustificationRules({this.incident = none, this.notApplicable = none});

  factory JustificationRules.fromJson(Map<String, dynamic> json) {
    return JustificationRules(
      incident: json['incident'] as int? ?? none,
      notApplicable: json['notApplicable'] as int? ?? none,
    );
  }

  /// Requirement for the selected choice ("non applicable" wins over incident).
  int requirementFor(ChoixReponseQuestion? choice) {
    if (choice == null) return none;
    if (choice.notApplicable) return notApplicable;
    if (choice.incident) return incident;
    return none;
  }

  static bool needsComment(int requirement) =>
      requirement == comment || requirement == commentAndPhoto;

  static bool needsPhoto(int requirement) =>
      requirement == photo || requirement == commentAndPhoto;

  /// Error message when the answer is missing its justification, else null.
  String? missingJustification(BuildContext context, ChoixReponseQuestion? choice,
      {required bool hasComment, required bool hasPhoto}) {
    final requirement = requirementFor(choice);
    final missingComment = needsComment(requirement) && !hasComment;
    final missingPhoto = needsPhoto(requirement) && !hasPhoto;
    final l10n = AppLocalizations.of(context)!;
    if (missingComment && missingPhoto) return l10n.justificationCommentAndPhotoRequired;
    if (missingComment) return l10n.justificationCommentRequired;
    if (missingPhoto) return l10n.justificationPhotoRequired;
    return null;
  }

  /// Short hint shown under the choice, or null when nothing is required.
  String? requirementHint(BuildContext context, ChoixReponseQuestion? choice) {
    final requirement = requirementFor(choice);
    final l10n = AppLocalizations.of(context)!;
    switch (requirement) {
      case comment:
        return l10n.justificationCommentRequired;
      case photo:
        return l10n.justificationPhotoRequired;
      case commentAndPhoto:
        return l10n.justificationCommentAndPhotoRequired;
      default:
        return null;
    }
  }
}
