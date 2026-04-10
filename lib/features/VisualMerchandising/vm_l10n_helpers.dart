import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String vmPhotosLabel(AppLocalizations l10n, int count) {
  if (count == 1) return l10n.vmPhotoCountOne;
  return l10n.vmPhotoCountMany(count);
}

String vmZonesRemainingLabel(AppLocalizations l10n, int remaining) {
  if (remaining == 1) return l10n.vmZonesRemainingOne;
  return l10n.vmZonesRemainingMany(remaining);
}

String vmPhotosLabelWithCheck(AppLocalizations l10n, int total, bool isComplete) {
  final base = vmPhotosLabel(l10n, total);
  return isComplete ? '$base ✓' : base;
}
