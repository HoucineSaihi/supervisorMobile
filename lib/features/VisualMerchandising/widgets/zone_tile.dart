import 'package:flutter/material.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';


class ZoneTile extends StatelessWidget {
  final ZoneStatDto zone;

  const ZoneTile({super.key, required this.zone});

  // Retourne la bonne couleur selon l'état de la zone
  Color get _backgroundColor {
    if (zone.isFinished) return const Color(0xFFE6FAF0); // vert pastel
    if (zone.isPartial)  return const Color(0xFFFFF4E5); // amber pastel
    return const Color(0xFFF4F9FF);                       // bleu pâle
  }

  Color get _borderColor {
    if (zone.isFinished) return const Color(0xFFB0E8CC);
    if (zone.isPartial)  return const Color(0xFFFCD34D);
    return const Color(0xFFE2EEF8);
  }

  // L'icône de statut en bas de la tuile
  Widget get _statusIcon {
    if (zone.isFinished) {
      return const Text('✅', style: TextStyle(fontSize: 12));
    }
    if (zone.isPartial) {
      return const Text('⏳', style: TextStyle(fontSize: 12));
    }
    return const Icon(Icons.circle_outlined, size: 14, color: Color(0xFFB0C8E0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji de la zone — on utilise le zoneCode pour choisir l'emoji
          Text(
            _emojiForCode(zone.zoneCode),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),

          // Nom de la zone
          Text(
            zone.zoneName,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A6D96),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // Nombre de photos
          Text(
            '${zone.imagesCount} photo${zone.imagesCount > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF7BACD8),
            ),
          ),

          const SizedBox(height: 4),
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