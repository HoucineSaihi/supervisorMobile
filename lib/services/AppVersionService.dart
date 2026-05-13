import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Détecte un changement de version d'APK et vide les caches applicatifs.
///
/// À appeler UNE SEULE FOIS dans [main] avant [runApp].
class AppVersionService {
  static const _lastVersionKey = 'app_last_known_version';

  static Future<void> clearCacheIfUpdated() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = '${info.version}+${info.buildNumber}';

    final prefs = await SharedPreferences.getInstance();
    final lastVersion = prefs.getString(_lastVersionKey);

    if (lastVersion != null && lastVersion != currentVersion) {
      await _clearAppCache(prefs);
    }

    await prefs.setString(_lastVersionKey, currentVersion);
  }

  static Future<void> _clearAppCache(SharedPreferences prefs) async {
    final keysToKeep = {_lastVersionKey};
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (!keysToKeep.contains(key)) {
        await prefs.remove(key);
      }
    }

    final storage = FlutterSecureStorage();
    await storage.deleteAll();
  }
}
