import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Manages guideline file cache with automatic cleanup
class GuidelineCacheManager {
  static const String _cacheFolderName = 'guidelines';
  
  // Cache limits
  static const int _maxCacheSizeMB = 100; // Maximum 100MB of cached files
  static const int _maxFileAgeDays = 30; // Files older than 30 days can be deleted
  static const int _maxFiles = 50; // Maximum number of files to keep

  /// Get the guidelines cache directory
  static Future<Directory> _getCacheDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final guidelinesDir = Directory('${appDocDir.path}/$_cacheFolderName');
    if (!await guidelinesDir.exists()) {
      await guidelinesDir.create(recursive: true);
    }
    return guidelinesDir;
  }

  /// Get current cache size in bytes
  static Future<int> getCacheSize() async {
    final cacheDir = await _getCacheDirectory();
    int totalSize = 0;
    
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    
    return totalSize;
  }

  /// Get cache size in MB
  static Future<double> getCacheSizeMB() async {
    final sizeBytes = await getCacheSize();
    return sizeBytes / (1024 * 1024);
  }

  /// Get number of files in cache
  static Future<int> getFileCount() async {
    final cacheDir = await _getCacheDirectory();
    int count = 0;
    
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: false)) {
        if (entity is File) {
          count++;
        }
      }
    }
    
    return count;
  }

  /// Clean up old files based on age
  static Future<int> cleanupOldFiles() async {
    final cacheDir = await _getCacheDirectory();
    int deletedCount = 0;
    final now = DateTime.now();
    final maxAge = Duration(days: _maxFileAgeDays);

    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          if (age > maxAge) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (e) {
              print('Error deleting old file ${entity.path}: $e');
            }
          }
        }
      }
    }

    return deletedCount;
  }

  /// Clean up files when cache exceeds size limit (LRU - Least Recently Used)
  static Future<int> cleanupBySize() async {
    final cacheDir = await _getCacheDirectory();
    final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
    
    // Get all files with their metadata
    final files = <_FileInfo>[];
    
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          files.add(_FileInfo(
            file: entity,
            size: await entity.length(),
            modified: stat.modified,
          ));
        }
      }
    }

    // Sort by last modified (oldest first - LRU)
    files.sort((a, b) => a.modified.compareTo(b.modified));

    // Calculate total size
    int totalSize = files.fold(0, (sum, f) => sum + f.size);
    int deletedCount = 0;

    // Delete oldest files until we're under the limit
    for (final fileInfo in files) {
      if (totalSize <= maxSizeBytes) break;
      
      try {
        await fileInfo.file.delete();
        totalSize -= fileInfo.size;
        deletedCount++;
      } catch (e) {
        print('Error deleting file ${fileInfo.file.path}: $e');
      }
    }

    return deletedCount;
  }

  /// Clean up files when file count exceeds limit (LRU)
  static Future<int> cleanupByCount() async {
    final cacheDir = await _getCacheDirectory();
    
    // Get all files with their metadata
    final files = <_FileInfo>[];
    
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          files.add(_FileInfo(
            file: entity,
            size: await entity.length(),
            modified: stat.modified,
          ));
        }
      }
    }

    // Sort by last modified (oldest first - LRU)
    files.sort((a, b) => a.modified.compareTo(b.modified));

    // Delete oldest files if count exceeds limit
    int deletedCount = 0;
    if (files.length > _maxFiles) {
      final filesToDelete = files.take(files.length - _maxFiles);
      for (final fileInfo in filesToDelete) {
        try {
          await fileInfo.file.delete();
          deletedCount++;
        } catch (e) {
          print('Error deleting file ${fileInfo.file.path}: $e');
        }
      }
    }

    return deletedCount;
  }

  /// Perform automatic cleanup (runs all cleanup strategies)
  /// Returns total number of files deleted
  static Future<int> performCleanup() async {
    int totalDeleted = 0;
    
    // Clean up old files first
    totalDeleted += await cleanupOldFiles();
    
    // Then clean up by count
    totalDeleted += await cleanupByCount();
    
    // Finally clean up by size
    totalDeleted += await cleanupBySize();
    
    return totalDeleted;
  }

  /// Clear all cached files
  static Future<int> clearAllCache() async {
    final cacheDir = await _getCacheDirectory();
    int deletedCount = 0;
    
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: false)) {
        if (entity is File) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            print('Error deleting file ${entity.path}: $e');
          }
        }
      }
    }
    
    return deletedCount;
  }

  /// Delete a specific file by path
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file $filePath: $e');
      return false;
    }
  }
}

/// Helper class to store file metadata
class _FileInfo {
  final File file;
  final int size;
  final DateTime modified;

  _FileInfo({
    required this.file,
    required this.size,
    required this.modified,
  });
}
