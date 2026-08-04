import 'package:flutter/material.dart';

import '../theme/comm_colors.dart';

/// Colour + icon for one operational entity type.
class ScopeVisuals {
  final Color fg;
  final Color bg;
  final IconData icon;

  const ScopeVisuals(this.fg, this.bg, this.icon);
}

/// Single source of truth for how an entity type is coloured and iconed.
///
/// Shared by the inline mention pills inside a message and the origin badge on an inbox
/// row, so an Incident looks like an Incident everywhere. Keyed by the backend's own
/// enum names (`ConversationScopeType` / `MessageEntityRef.EntityType`) so both callers
/// can hand through whatever the server sent without translating first.
ScopeVisuals scopeVisualsFor(String entityType) {
  switch (entityType) {
    case 'Incident':
      return const ScopeVisuals(
        Color(0xFFB91C1C),
        Color(0xFFFEF2F2),
        Icons.report_problem_outlined,
      );
    case 'Mission':
    case 'Checklist':
      return const ScopeVisuals(
        Color(0xFFB45309),
        Color(0xFFFFFBEB),
        Icons.assignment_outlined,
      );
    case 'Campaign':
    case 'VmExecution':
      return const ScopeVisuals(
        Color(0xFF6D28D9),
        Color(0xFFF5F3FF),
        Icons.campaign_outlined,
      );
    case 'Boutique':
      return const ScopeVisuals(
        Color(0xFF15803D),
        Color(0xFFF0FDF4),
        Icons.store_outlined,
      );
    case 'CorrectiveAction':
      return const ScopeVisuals(
        Color(0xFF0F766E),
        Color(0xFFF0FDFA),
        Icons.build_outlined,
      );
    default:
      return const ScopeVisuals(
        CommColors.blueDark,
        CommColors.blueSoft,
        Icons.person_outline,
      );
  }
}

/// Short human label for a scope badge. Kept terse — an inbox row has very little
/// horizontal room, and the icon already carries most of the meaning.
String scopeLabelFor(String entityType) {
  switch (entityType) {
    case 'Incident':
      return 'Incident';
    case 'Mission':
      return 'Mission';
    case 'Checklist':
      return 'Checklist';
    case 'Campaign':
      return 'Campaign';
    case 'VmExecution':
      return 'VM';
    case 'Boutique':
      return 'Store';
    case 'CorrectiveAction':
      return 'Action';
    case 'Audit':
      return 'Audit';
    case 'Role':
      return 'Role';
    default:
      return entityType;
  }
}
