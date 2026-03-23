import 'package:flutter/material.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';


class ZoneRow extends StatelessWidget {
  final ZoneStatDto zone;
  final bool isCompleteLocally;  // tient compte des photos ajoutées
  final int localPhotoCount;     // photos ajoutées localement
  final VoidCallback onTap;

  const ZoneRow({
    super.key,
    required this.zone,
    required this.isCompleteLocally,
    required this.localPhotoCount,
    required this.onTap,
  });

  // ── Couleurs selon l'état ───────────────────────────
  Color get _bgColor {
    if (isCompleteLocally)  return const Color(0xFFE6FAF0);
    if (zone.isPartial)     return const Color(0xFFFFF4E5);
    return Colors.white;
  }

  Color get _borderColor {
    if (isCompleteLocally)  return const Color(0xFFB0E8CC);
    if (zone.isPartial)     return const Color(0xFFFCD34D);
    return const Color(0xFFE2EEF8);
  }

  Color get _progressColor {
    if (isCompleteLocally)  return const Color(0xFF27AE73);
    if (zone.isPartial)     return const Color(0xFFF5A623);
    return const Color(0xFF1E5FAA);
  }

  // ── Total des photos (backend + local) ─────────────
  int get _totalPhotos => zone.imagesCount + localPhotoCount;

  // ── Widget du statut (droite) ───────────────────────
  Widget get _statusWidget {
    if (isCompleteLocally) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE6FAF0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB0E8CC)),
        ),
        child: const Text(
          '✓ Complet',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A7A4A),
          ),
        ),
      );
    }
    if (zone.isPartial || localPhotoCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Text(
          '$_totalPhotos photo${_totalPhotos > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC87700),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2EEF8)),
      ),
      child: const Text(
        'À faire',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7BACD8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [

              // ── Emoji dans un cercle ─────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _bgColor == Colors.white
                      ? const Color(0xFFEAF3FD)
                      : _bgColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _emojiForCode(zone.zoneCode),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Nom + barre de progression ───────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + badge statut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            zone.zoneName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F2D5E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusWidget,
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Barre de progression
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              // Progress : on divise par 1 si zone vide
                              // juste pour montrer visuellement l'état
                              value: isCompleteLocally ? 1.0
                                  : (zone.isPartial || localPhotoCount > 0)
                                  ? 0.5
                                  : 0.0,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2EEF8),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _progressColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalPhotos photo${_totalPhotos > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A6D96),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Flèche droite ─────────────────────────
              Icon(
                Icons.chevron_right_rounded,
                color: isCompleteLocally
                    ? const Color(0xFF27AE73)
                    : const Color(0xFFB0C8E0),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emojiForCode(String code) {
    final c = code.toUpperCase();
    if (c.startsWith('VP') || c.startsWith('VL')) return '🪟';
    if (c.startsWith('WD')) return '🧱';
    if (c.startsWith('EA')) return '🪑';
    if (c.startsWith('PE')) return '💡';
    if (c.startsWith('ZC')) return '🛍';
    if (c.startsWith('ZS')) return '📦';
    if (c.startsWith('ZR')) return '🚪';
    if (c.startsWith('ZE')) return '🎪';
    return '📍';
  }
}