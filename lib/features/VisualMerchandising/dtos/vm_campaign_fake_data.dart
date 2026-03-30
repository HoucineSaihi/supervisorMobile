// ─────────────────────────────────────────────────────────
// vm_campaign_fake_data.dart
// Données de test qui imitent exactement la réponse du backend.
// On utilise ça pendant le dev pour ne pas dépendre de l'API.
// ─────────────────────────────────────────────────────────

import 'vm_campaign_dto.dart';

// Simule la réponse JSON du backend, parsée en objets Dart
final List<VmCampaignDto> fakeCampaigns = [
  VmCampaignDto(
    campaignId: 1,
    siteId: 1,
    status: CampaignStatus.inProgress,
    endDate: DateTime(2025, 6, 15, 23, 59, 59),
    libelle: 'Collection Été 2025',
    zoneCount: 5,
    containsGuideline: true,
    executionsStats: [
      ExecutionStatsDto(
        guidelineId: 10,
        guidelineName: 'Guideline Vitrine Principale',
        guidelineDescription: 'Instructions pour la mise en place de la vitrine',
        zoneStats: [
          ZoneStatDto(
            zoneId: 1,
            zoneName: 'Vitrine Principale',
            zoneCode: 'VP001',
            imagesCount: 2,
            isFinished: true,
          ),
          ZoneStatDto(
            zoneId: 2,
            zoneName: 'Wall Display',
            zoneCode: 'WD002',
            imagesCount: 3,
            isFinished: true,
          ),
          ZoneStatDto(
            zoneId: 3,
            zoneName: 'Espace Assise',
            zoneCode: 'EA003',
            imagesCount: 1,
            isFinished: true,
          ),
          ZoneStatDto(
            zoneId: 4,
            zoneName: 'PLV Entrée',
            zoneCode: 'PE004',
            imagesCount: 1,
            isFinished: false, // partielle
          ),
          ZoneStatDto(
            zoneId: 5,
            zoneName: 'Zone Caisse',
            zoneCode: 'ZC005',
            imagesCount: 0,
            isFinished: false, // vide
          ),
        ],
      ),
    ],
  ),
  VmCampaignDto(
    campaignId: 2,
    siteId: 1,
    status: CampaignStatus.notStarted,
    endDate: DateTime(2025, 7, 30, 23, 59, 59),
    libelle: 'Rentrée Automne 2025',
    zoneCount: 3,
    containsGuideline: true,
    executionsStats: [
      ExecutionStatsDto(
        guidelineId: 15,
        guidelineName: 'Guideline Rentrée',
        guidelineDescription: 'Mise en place pour la collection automne',
        zoneStats: [
          ZoneStatDto(
            zoneId: 1, zoneName: 'Vitrine',
            zoneCode: 'VP001', imagesCount: 0, isFinished: false,
          ),
          ZoneStatDto(
            zoneId: 6, zoneName: 'Zone Réception',
            zoneCode: 'ZR006', imagesCount: 0, isFinished: false,
          ),
          ZoneStatDto(
            zoneId: 7, zoneName: 'Zone Événement',
            zoneCode: 'ZE007', imagesCount: 0, isFinished: false,
          ),
        ],
      ),
    ],
  ),
];

// Fake boutiques (on ajoutera l'API boutiques plus tard)
class FakeSite {
  final int id;
  final String name;
  final String city;

  const FakeSite({
    required this.id,
    required this.name,
    required this.city,
  });
}

final List<FakeSite> fakeSites = [
  FakeSite(id: 1, name: 'Boutique Alger Centre', city: 'Alger'),
  FakeSite(id: 2, name: 'Boutique Oran Bir El Djir', city: 'Oran'),
  FakeSite(id: 3, name: 'Boutique Constantine', city: 'Constantine'),
];