import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'zone_tile.dart';

class CampaignCard extends StatelessWidget {
  final VmCampaignDto campaign;
  final int pendingLocalPhotosCount;
  final int pendingLocalZonesCount;
  final Map<int, int> pendingLocalPhotosByZone;
  final VoidCallback? onEnter;      // quand on appuie sur "Entrer"
  final VoidCallback? onGuideline;  // quand on appuie sur "Guideline"

  const CampaignCard({
    super.key,
    required this.campaign,
    this.pendingLocalPhotosCount = 0,
    this.pendingLocalZonesCount = 0,
    this.pendingLocalPhotosByZone = const <int, int>{},
    this.onEnter,
    this.onGuideline,
  });

  bool get _hasLocalPending {
    return pendingLocalPhotosCount > 0 &&
        campaign.status != CampaignStatus.submitted &&
        campaign.status != CampaignStatus.approved &&
        campaign.status != CampaignStatus.disapproved;
  }

  bool get _isSubmittedPending => campaign.status == CampaignStatus.submitted;
  bool get _isApproved => campaign.status == CampaignStatus.approved;
  bool get _isDisapproved => campaign.status == CampaignStatus.disapproved;

  double get _displayProgress {
    if (!_hasLocalPending) return campaign.completionRatio;
    if (campaign.completionRatio >= 1.0) return 1.0;
    return campaign.completionRatio < 0.5 ? 0.5 : campaign.completionRatio;
  }

  Color get _displayProgressColor {
    if (_isDisapproved) return const Color(0xFFE74C3C);
    if (_isApproved) return const Color(0xFF27AE73);
    if (_isSubmittedPending) return const Color(0xFFF5A623);
    if (_hasLocalPending) return const Color(0xFFF5A623);
    return _ringColor(campaign.completionRatio);
  }

  List<Color> get _headerGradientColors {
    if (_isDisapproved) {
      return const [Color(0xFF8B0000), Color(0xFFB71C1C), Color(0xFFE74C3C)];
    }
    if (_isApproved) {
      return const [Color(0xFF1A7A4A), Color(0xFF27AE73), Color(0xFF4FD38E)];
    }
    if (_isSubmittedPending) {
      return const [Color(0xFFB86B00), Color(0xFFF5A623), Color(0xFFFFC55C)];
    }
    return const [Color(0xFF1B3F72), Color(0xFF1E5FAA), Color(0xFF4A9EDD)];
  }

  // Only server-approved zones count — local pending photos are not yet approved
  int get _displayApprovedZones => campaign.totalApprovedZones;

  int get _displayPhotoCount {
    if (!_hasLocalPending) return campaign.totalImages;
    return campaign.totalImages + pendingLocalPhotosCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          _buildBanner(l10n),
          _buildInfoRow(l10n),
          _buildZoneGrid(l10n),
          _buildProgressBar(l10n),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  // ── 1. Bannière bleue en haut ────────────────────────
  Widget _buildBanner(AppLocalizations l10n) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _headerGradientColors,
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
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusBadge(
                      status: campaign.status,
                      hasLocalPending: _hasLocalPending,
                    ),
                    if (campaign.unreadCommentCount > 0)
                      _UnreadCommentsBadge(count: campaign.unreadCommentCount),
                  ],
                ),
              ),
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
                      // Afficher uniquement la date limite, sans indication "dépassée".
                      DateFormat('dd/MM/yyyy').format(campaign.endDate),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.vmVisualMerchBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
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
  Widget _buildInfoRow(AppLocalizations l10n) {
    final pct = (_displayProgress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Anneau SVG custom via CustomPaint — hidden if locally pending
          if (!_hasLocalPending)
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(64, 64),
                    painter: _RingPainter(
                      progress: _displayProgress,
                      color: _displayProgressColor,
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

          if (!_hasLocalPending) const SizedBox(width: 14),

          // Méta : zones + images + guidelines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(
                  icon: Icons.grid_view_rounded,
                  label: l10n.vmMetaZonesApproved(
                    _displayApprovedZones,
                    campaign.totalZones,
                  ),
                  color: _hasLocalPending
                      ? const Color(0xFFB86B00)
                      : const Color(0xFF4A6D96),
                ),
                const SizedBox(height: 5),
                _MetaRow(
                  icon: Icons.photo_camera_outlined,
                  label: l10n.vmMetaPhotosSent(_displayPhotoCount),
                  color: _hasLocalPending
                      ? const Color(0xFFB86B00)
                      : const Color(0xFF4A6D96),
                ),
                const SizedBox(height: 5),
                if (campaign.containsGuideline && campaign.executionsStats.isNotEmpty)
                  _MetaRow(
                    icon: Icons.picture_as_pdf_outlined,
                    label: campaign.executionsStats.length == 1
                        ? (campaign.executionsStats.first.guidelineName ??
                            l10n.vmGuidelineDisplayFallback(1))
                        : l10n.vmGuidelinesCount(campaign.executionsStats.length),
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
  Widget _buildZoneGrid(AppLocalizations l10n) {
    // Si plusieurs guidelines, on les groupe par guideline
    if (campaign.executionsStats.length > 1) {
      return _buildGroupedZoneGrid(l10n);
    }

    // Sinon, affichage simple (un seul guideline)
    final zones = campaign.executionsStats.firstOrNull?.zoneStats ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.vmProgressionByZoneTitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8AB2D4),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: zones.length,
            itemBuilder: (_, i) => ZoneTile(
              zone: zones[i],
              pendingLocalPhotosCount:
                  pendingLocalPhotosByZone[zones[i].zoneId] ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Grille groupée par guideline ──────────────────────
  Widget _buildGroupedZoneGrid(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.vmProgressionByZoneTitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8AB2D4),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          // Liste des guidelines avec leurs zones
          ...campaign.executionsStats.asMap().entries.map((entry) {
            final index = entry.key;
            final guideline = entry.value;
            final isLast = index == campaign.executionsStats.length - 1;

            return _GuidelineSection(
              l10n: l10n,
              guideline: guideline,
              guidelineIndex: index + 1,
              isLast: isLast,
              pendingLocalPhotosByZone: pendingLocalPhotosByZone,
            );
          }),
        ],
      ),
    );
  }

  // ── 4. Barre de progression globale ─────────────────
  Widget _buildProgressBar(AppLocalizations l10n) {
    if (_hasLocalPending) {
      return const SizedBox.shrink();
    }

    final pct = (_displayProgress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.vmGlobalProgress,
                style: const TextStyle(
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
              value: _displayProgress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2EEF8),
              valueColor: AlwaysStoppedAnimation<Color>(
                _displayProgressColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Footer : boutons ──────────────────────────────
  Widget _buildFooter(AppLocalizations l10n) {
    final hasMultipleGuidelines = campaign.executionsStats.length > 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton Guideline(s)
          if (campaign.containsGuideline)
            OutlinedButton.icon(
              onPressed: onGuideline,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
              label: Text(hasMultipleGuidelines
                  ? l10n.vmGuidelinesButton(campaign.executionsStats.length)
                  : l10n.vmGuidelineButton),
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
                    : _isDisapproved
                        ? const Color(0xFFE74C3C)
                        : _isApproved
                            ? const Color(0xFF27AE73)
                            : _isSubmittedPending
                                ? const Color(0xFFF5A623)
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
                campaign.status == CampaignStatus.submitted ||
                        campaign.status == CampaignStatus.approved ||
                        campaign.status == CampaignStatus.disapproved
                    ? l10n.vmViewExecution
                    : campaign.canSubmit
                        ? l10n.vmSubmitCampaignEmailCta
                        : l10n.vmEnterCampaign,
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

// ── Badge commentaires non lus ─────────────────────────
class _UnreadCommentsBadge extends StatelessWidget {
  final int count;
  const _UnreadCommentsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget interne : badge de statut ────────────────────
class _StatusBadge extends StatelessWidget {
  final CampaignStatus status;
  final bool hasLocalPending;

  const _StatusBadge({
    required this.status,
    this.hasLocalPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    String label;
    Color  bg;

    if (hasLocalPending &&
        status != CampaignStatus.submitted &&
        status != CampaignStatus.approved &&
        status != CampaignStatus.disapproved) {
      label = isFrench ? '⏳ En cours localement' : '⏳ In progress locally';
      bg = const Color(0xFFF5A623).withOpacity(0.28);
      return Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    switch (status) {
      case CampaignStatus.inProgress:
        label = '● ${l10n.inProgress}';
        bg    = Colors.white.withOpacity(0.22);
        break;
      case CampaignStatus.submitted:
        label = '✓ ${l10n.completed}';
        bg    = const Color(0xFFF5A623).withOpacity(0.3);
        break;
      case CampaignStatus.approved:
        label = isFrench ? '✓ Approuvee' : '✓ Approved';
        bg    = const Color(0xFF27AE73).withOpacity(0.3);
        break;
      case CampaignStatus.disapproved:
        label = isFrench ? '✕ Desapprouvee' : '✕ Disapproved';
        bg    = const Color(0xFF8B0000).withOpacity(0.25);
        break;
      case CampaignStatus.cancelled:
        label = '✕ ${l10n.cancelled}';
        bg    = const Color(0xFF8B0000).withOpacity(0.25);
        break;
      case CampaignStatus.notStarted:
        label = '○ ${l10n.planned}';
        bg    = Colors.white.withOpacity(0.15);
        break;
      default:
        label = '○ ${l10n.unknown}';
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

class _LocalDraftBadge extends StatelessWidget {
  final int count;

  const _LocalDraftBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final label = isFrench ? 'Local ($count) non envoye' : 'Local ($count) not sent';

    return Container(
      constraints: const BoxConstraints(maxWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623).withOpacity(0.24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
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

// ── Widget : Section d'un guideline avec ses zones ──────
class _GuidelineSection extends StatelessWidget {
  final AppLocalizations l10n;
  final ExecutionStatsDto guideline;
  final int guidelineIndex;
  final bool isLast;
  final Map<int, int> pendingLocalPhotosByZone;

  const _GuidelineSection({
    required this.l10n,
    required this.guideline,
    required this.guidelineIndex,
    required this.isLast,
    required this.pendingLocalPhotosByZone,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (guideline.approvedAndSubmittedZones /
            (guideline.totalZones == 0 ? 1 : guideline.totalZones) *
            100)
        .toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header du guideline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2EEF8)),
          ),
          child: Row(
            children: [
              // Badge numéro
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5FAA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$guidelineIndex',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nom du guideline
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guideline.guidelineName ??
                          l10n.vmGuidelineNumberedFallback(guidelineIndex),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2D5E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (guideline.guidelineDescription != null)
                      Text(
                        guideline.guidelineDescription!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7BACD8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Progression du guideline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2EEF8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E5FAA),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${guideline.approvedZones}/${guideline.totalZones})',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF7BACD8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Grille des zones de ce guideline
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: guideline.zoneStats.length,
          itemBuilder: (_, i) => ZoneTile(
            zone: guideline.zoneStats[i],
            pendingLocalPhotosCount:
                pendingLocalPhotosByZone[guideline.zoneStats[i].zoneId] ?? 0,
          ),
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }
}