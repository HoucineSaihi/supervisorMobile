import 'package:flutter/material.dart';
import '../dtos/vm_campaign_dto.dart';
import 'zone_tile.dart';

class CampaignCard extends StatelessWidget {
  final VmCampaignDto campaign;
  final VoidCallback? onEnter;      // quand on appuie sur "Entrer"
  final VoidCallback? onGuideline;  // quand on appuie sur "Guideline"

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onEnter,
    this.onGuideline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5FAA).withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBanner(),
          _buildInfoRow(),
          _buildZoneGrid(),
          _buildProgressBar(),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── 1. Bannière bleue en haut ────────────────────────
  Widget _buildBanner() {
    return Container(
      height: 110,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges en haut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge statut
              _StatusBadge(status: campaign.status),
              // Badge deadline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      campaign.isOverdue
                          ? 'Deadline dépassée'
                          : '${campaign.daysRemaining}j restants',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: campaign.isOverdue
                            ? const Color(0xFFFF8A80)
                            : Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Titre + label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  campaign.libelle,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Visual Merch',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Ligne : anneau de progression + méta ──────────
  Widget _buildInfoRow() {
    final stats = campaign.executionStats;
    final pct   = (stats.completionRatio * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Anneau SVG custom via CustomPaint
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _RingPainter(
                    progress: stats.completionRatio,
                    color: _ringColor(stats.completionRatio),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3F72),
                        height: 1,
                      ),
                    ),
                    const Text(
                      '%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8AB2D4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Méta : zones + images + guideline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(
                  icon: Icons.grid_view_rounded,
                  label:
                  '${stats.completedZones} / ${stats.totalZones} zones complètes',
                ),
                const SizedBox(height: 5),
                _MetaRow(
                  icon: Icons.photo_camera_outlined,
                  label: '${stats.totalImages} photos envoyées',
                ),
                const SizedBox(height: 5),
                if (campaign.containsGuideline)
                  _MetaRow(
                    icon: Icons.picture_as_pdf_outlined,
                    label: campaign.executionStats.guidelineName,
                    color: const Color(0xFF1E5FAA),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Grille des zones ──────────────────────────────
  Widget _buildZoneGrid() {
    final zones = campaign.executionStats.zoneStats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRESSION PAR ZONE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8AB2D4),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,        // important : la grid s'adapte à son contenu
            physics: const NeverScrollableScrollPhysics(), // scroll géré par le parent
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: zones.length,
            itemBuilder: (_, i) => ZoneTile(zone: zones[i]),
          ),
        ],
      ),
    );
  }

  // ── 4. Barre de progression globale ─────────────────
  Widget _buildProgressBar() {
    final stats  = campaign.executionStats;
    final pct    = (stats.completionRatio * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Avancement global',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A6D96),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E5FAA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats.completionRatio,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2EEF8),
              valueColor: AlwaysStoppedAnimation<Color>(
                _ringColor(stats.completionRatio),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Footer : boutons ──────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton Guideline
          if (campaign.containsGuideline)
            OutlinedButton.icon(
              onPressed: onGuideline,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
              label: const Text('Guideline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E5FAA),
                side: const BorderSide(color: Color(0xFFB8D9F5)),
                backgroundColor: const Color(0xFFEAF3FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          const SizedBox(width: 10),

          // Bouton principal — Entrer ou Soumettre
          Expanded(
            child: ElevatedButton(
              onPressed: onEnter,
              style: ElevatedButton.styleFrom(
                backgroundColor: campaign.canSubmit
                    ? const Color(0xFF27AE73)
                    : const Color(0xFF1E5FAA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 4,
                shadowColor: const Color(0xFF1E5FAA).withOpacity(0.3),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                campaign.canSubmit
                    ? '✉️  Soumettre la campagne'
                    : 'Entrer dans la campagne →',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Couleur de l'anneau selon le taux
  Color _ringColor(double ratio) {
    if (ratio >= 1.0) return const Color(0xFF27AE73); // vert
    if (ratio >= 0.5) return const Color(0xFF1E5FAA); // bleu
    return const Color(0xFFF5A623);                    // amber
  }
}

// ── Widget interne : une ligne de méta ──────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaRow({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF4A6D96),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Widget interne : badge de statut ────────────────────
class _StatusBadge extends StatelessWidget {
  final CampaignStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color  bg;

    switch (status) {
      case CampaignStatus.inProgress:
        label = '● En cours';
        bg    = Colors.white.withOpacity(0.22);
        break;
      case CampaignStatus.submitted:
        label = '✓ Soumis';
        bg    = const Color(0xFF27AE73).withOpacity(0.3);
        break;
      default:
        label = '○ Non démarré';
        bg    = Colors.white.withOpacity(0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── CustomPainter : dessine l'anneau de progression ─────
// C'est la version Flutter d'un SVG circle progress
class _RingPainter extends CustomPainter {
  final double progress; // 0.0 à 1.0
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 5;
    const strokeWidth = 5.0;

    // Cercle de fond (gris)
    final bgPaint = Paint()
      ..color = const Color(0xFFE8F1FB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Arc de progression (coloré)
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // drawArc : commence à -π/2 (haut) et tourne dans le sens des aiguilles
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,             // startAngle : 12h
      2 * 3.14159 * progress,   // sweepAngle : proportionnel au progrès
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}