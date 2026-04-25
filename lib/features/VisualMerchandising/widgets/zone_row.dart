import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/vm_l10n_helpers.dart';


class ZoneRow extends StatelessWidget {
  final ZoneStatDto zone;
  final bool isZoneValidated;
  final bool hasLocalPending;
  final int totalPhotoCount;
  final VoidCallback onTap;
  final String? issueText;

  const ZoneRow({
    super.key,
    required this.zone,
    required this.isZoneValidated,
    required this.hasLocalPending,
    required this.totalPhotoCount,
    required this.onTap,
    this.issueText,
  });

  // ── Couleurs selon l'état ───────────────────────────
  Color get _bgColor {
    if (zone.isDisapproved) return const Color(0xFFFFECE9);
    if (zone.isApproved || isZoneValidated) return const Color(0xFFE6FAF0);
    if (hasLocalPending || zone.isSubmitted) return const Color(0xFFFFF4E5);
    return Colors.white;
  }

  Color get _borderColor {
    if (zone.isDisapproved) return const Color(0xFFF3A9A0);
    if (zone.isApproved || isZoneValidated) return const Color(0xFFB0E8CC);
    if (hasLocalPending || zone.isSubmitted) return const Color(0xFFFCD34D);
    return const Color(0xFFE2EEF8);
  }

  Color get _progressColor {
    if (zone.isDisapproved) return const Color(0xFFE74C3C);
    if (zone.isApproved || isZoneValidated) return const Color(0xFF27AE73);
    if (hasLocalPending || zone.isSubmitted) return const Color(0xFFF5A623);
    return const Color(0xFF1E5FAA);
  }

  // ── Widget du statut (droite) ───────────────────────
  Widget _statusWidget(AppLocalizations l10n) {
    final isFrench = l10n.localeName.toLowerCase().startsWith('fr');

    if (zone.isDisapproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECE9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF3A9A0)),
        ),
        child: Text(
          isFrench ? 'Desapprouvee' : 'Disapproved',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC62828),
          ),
        ),
      );
    }
    if (zone.isApproved || isZoneValidated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE6FAF0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB0E8CC)),
        ),
        child: Text(
          isFrench ? 'Approuvee' : 'Approved',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A7A4A),
          ),
        ),
      );
    }
    if (hasLocalPending || zone.isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF7C66A)),
        ),
        child: Text(
          isFrench ? 'Soumise' : 'Submitted',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB86B00),
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
      child: Text(
        l10n.vmZoneStatusTodo,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7BACD8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        _statusWidget(l10n),
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
                              value: isZoneValidated
                                  ? 1.0
                                  : zone.isDisapproved
                                  ? 1.0
                                  : (hasLocalPending || zone.isSubmitted)
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
                          vmPhotosLabel(l10n, totalPhotoCount),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A6D96),
                          ),
                        ),
                      ],
                    ),

                    // Issue snippet (disapproved only)
                    if (zone.isDisapproved && issueText != null && issueText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 11,
                              color: Color(0xFFE74C3C),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                issueText!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE74C3C),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Flèche droite ─────────────────────────
              Icon(
                Icons.chevron_right_rounded,
                color: isZoneValidated
                    ? const Color(0xFF27AE73)
                    : zone.isDisapproved
                    ? const Color(0xFFE74C3C)
                    : zone.isSubmitted
                    ? const Color(0xFFF5A623)
                    : zone.isApproved
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