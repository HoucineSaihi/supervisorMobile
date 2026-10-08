import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

/// Shows which build is installed on this device (name, version, build number).
///
/// The values are read from the installed binary, which is fed from `version:`
/// in pubspec.yaml — so this screen is the quickest way to check that the right
/// build was delivered (see RELEASING.md).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = snapshot.data;
          if (info == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoRow(
                icon: Iconsax.mobile,
                label: l10n.aboutApplication,
                value: info.appName,
              ),
              _InfoRow(
                icon: Iconsax.tag,
                label: l10n.aboutVersion,
                value: info.version,
              ),
              _InfoRow(
                icon: Iconsax.hashtag,
                label: l10n.aboutBuild,
                value: info.buildNumber,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: '${info.version}+${info.buildNumber}'),
                  ),
                  icon: const Icon(Iconsax.copy, size: 18),
                  label: Text(l10n.aboutCopyHint),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: TColors.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
