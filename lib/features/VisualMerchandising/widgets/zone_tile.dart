import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/vm_l10n_helpers.dart';


class ZoneTile extends StatelessWidget {
  final ZoneStatDto zone;
  final int pendingLocalPhotosCount;

  const ZoneTile({
    super.key,
    required this.zone,
    this.pendingLocalPhotosCount = 0,
  });

  bool get _hasLocalPending => pendingLocalPhotosCount > 0;
  int get _displayPhotoCount => zone.imagesCount + pendingLocalPhotosCount;

  // Retourne la bonne couleur selon l'état de la zone
  Color get _backgroundColor {
    if (zone.isDisapproved) return const Color(0xFFFFECE9);
    if (zone.isApproved) return const Color(0xFFE6FAF0);
    if (_hasLocalPending || zone.isSubmitted) return const Color(0xFFFFF4E5);
    return const Color(0xFFF4F9FF);                       // bleu pâle
  }

  Color get _borderColor {
    if (zone.isDisapproved) return const Color(0xFFF3A9A0);
    if (zone.isApproved) return const Color(0xFFB0E8CC);
    if (_hasLocalPending || zone.isSubmitted) return const Color(0xFFFCD34D);
    return const Color(0xFFE2EEF8);
  }

  // L'icône de statut en bas de la tuile
  Widget get _statusIcon {
    if (zone.isDisapproved) {
      return const Text('❌', style: TextStyle(fontSize: 12));
    }
    if (zone.isApproved) {
      return const Text('✅', style: TextStyle(fontSize: 12));
    }
    if (_hasLocalPending || zone.isSubmitted) {
      return const Text('⏳', style: TextStyle(fontSize: 12));
    }
    return const Icon(Icons.circle_outlined, size: 14, color: Color(0xFFB0C8E0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Emoji de la zone — on utilise le zoneCode pour choisir l'emoji
          Text(
            _emojiForCode(zone.zoneCode),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 3),

          // Nom de la zone
          Expanded(
            child: Center(
              child: Text(
                zone.zoneName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A6D96),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 1),

          // Nombre de photos
          Text(
            vmPhotosLabel(l10n, _displayPhotoCount),
            style: TextStyle(
              fontSize: 9,
              color: zone.isDisapproved
                  ? const Color(0xFFC62828)
                  : (_hasLocalPending || zone.isSubmitted)
                  ? const Color(0xFFB86B00)
                  : zone.isApproved
                      ? const Color(0xFF1A7A4A)
                      : const Color(0xFF7BACD8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),
          _statusIcon,
        ],
      ),
    );
  }

  // Associe un emoji à chaque type de zone selon son code
  String _emojiForCode(String code) {
    final c = code.toUpperCase();
    if (c.startsWith('VP') || c.startsWith('VL')) return '🪟'; // vitrine
    if (c.startsWith('WD'))                        return '🧱'; // wall display
    if (c.startsWith('EA'))                        return '🪑'; // assise
    if (c.startsWith('PE'))                        return '💡'; // PLV
    if (c.startsWith('ZC'))                        return '🛍'; // caisse
    if (c.startsWith('ZS'))                        return '📦'; // stock/promos
    if (c.startsWith('ZR'))                        return '🚪'; // réception
    if (c.startsWith('ZE'))                        return '🎪'; // événement
    return '📍'; // fallback
  }
}