import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../dtos/vm_campaign_dto.dart';
import '../dtos/vm_guideline_asset_dto.dart';
import '../services/vm_service.dart';

/// Handles opening guideline documents
class GuidelineHandler {
  static final VmService _vmService = VmService();

  /// Opens guideline document(s) for a campaign
  /// If multiple guidelines, shows a dialog to select one
  static Future<void> openGuideline(BuildContext context, VmCampaignDto campaign) async {
    if (!campaign.containsGuideline || campaign.executionsStats.isEmpty) {
      _showError(context, 'Aucune guideline disponible pour cette campagne.');
      return;
    }

    // Si un seul guideline, ouvrir directement
    if (campaign.executionsStats.length == 1) {
      await _openGuidelineAssets(context, campaign.executionsStats.first);
      return;
    }

    // Si plusieurs guidelines, afficher un dialog de sélection
    await _showGuidelineSelector(context, campaign);
  }

  /// Affiche un dialog pour sélectionner un guideline
  static Future<void> _showGuidelineSelector(
      BuildContext context, VmCampaignDto campaign) async {
    final selectedGuideline = await showDialog<ExecutionStatsDto>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Sélectionner un guideline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2D5E),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: campaign.executionsStats.length,
              itemBuilder: (context, index) {
                final guideline = campaign.executionsStats[index];
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5FAA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    guideline.guidelineName ?? 'Guideline ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F2D5E),
                    ),
                  ),
                  subtitle: guideline.guidelineDescription != null
                      ? Text(
                          guideline.guidelineDescription!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7BACD8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF7BACD8),
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop(guideline);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedGuideline != null) {
      await _openGuidelineAssets(context, selectedGuideline);
    }
  }

  /// Ouvre les assets d'un guideline
  static Future<void> _openGuidelineAssets(
      BuildContext context, ExecutionStatsDto guideline) async {
    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E5FAA),
          ),
        ),
      );

      // Récupérer les assets
      final assets = await _vmService.getGuidelineAssets(guideline.guidelineId);

      // Fermer le loader
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (assets.isEmpty) {
        if (context.mounted) {
          _showError(context, 'Aucun document disponible pour ce guideline.');
        }
        return;
      }

      // Si un seul document, l'ouvrir directement
      if (assets.length == 1) {
        await _openAsset(context, assets.first);
        return;
      }

      // Si plusieurs documents, afficher un dialog de sélection
      if (context.mounted) {
        await _showAssetSelector(context, assets);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le loader
        _showError(context, 'Erreur lors du chargement des documents: ${e.toString()}');
      }
    }
  }

  /// Affiche un dialog pour sélectionner un asset
  static Future<void> _showAssetSelector(
      BuildContext context, List<VmGuidelineAsset> assets) async {
    final selectedAsset = await showDialog<VmGuidelineAsset>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Sélectionner un document',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2D5E),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return ListTile(
                  leading: Icon(
                    asset.isDocument
                        ? Icons.picture_as_pdf
                        : asset.isImage
                            ? Icons.image
                            : Icons.insert_drive_file,
                    color: const Color(0xFF1E5FAA),
                    size: 28,
                  ),
                  title: Text(
                    asset.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F2D5E),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (asset.description != null)
                        Text(
                          asset.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7BACD8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${asset.assetType ?? "Fichier"} • ${asset.formattedSize}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8AB2D4),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF7BACD8),
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop(asset);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedAsset != null) {
      await _openAsset(context, selectedAsset);
    }
  }

  /// Ouvre un asset (document) avec l'app par défaut du mobile
  /// Télécharge d'abord le fichier depuis l'endpoint de download
  static Future<void> _openAsset(BuildContext context, VmGuidelineAsset asset) async {
    try {
      // Afficher un loader pendant le téléchargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF1E5FAA),
              ),
              const SizedBox(height: 16),
              Text(
                'Téléchargement de ${asset.fileName}...',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F2D5E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Télécharger le fichier (vérifie si déjà téléchargé)
      final filePath = await _vmService.downloadGuidelineAsset(
        asset.id,
        asset.fileName,
        storedFileName: asset.storedFileName,
      );

      // Fermer le loader
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Vérifier que le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        if (context.mounted) {
          _showError(context, 'Le fichier téléchargé n\'existe pas.');
        }
        return;
      }

      // Update file timestamp for LRU cache (keeps frequently accessed files longer)
      try {
        await file.setLastModified(DateTime.now());
      } catch (e) {
        // Ignore if we can't update timestamp
        print('Could not update file timestamp: $e');
      }

      // Ouvrir le fichier avec l'app par défaut du système
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        if (context.mounted) {
          String errorMessage = 'Impossible d\'ouvrir le fichier: ${asset.fileName}';
          if (result.message != null && result.message!.isNotEmpty) {
            errorMessage += '\n${result.message}';
          }
          _showError(context, errorMessage);
        }
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le loader
        _showError(context, 'Erreur lors du téléchargement/ouverture: ${e.toString()}');
      }
    }
  }

  /// Affiche un message d'erreur
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
