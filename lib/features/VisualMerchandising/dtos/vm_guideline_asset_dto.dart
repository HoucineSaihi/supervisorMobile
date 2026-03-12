// ─────────────────────────────────────────────────────────
// vm_guideline_asset_dto.dart
// DTO for guideline assets (documents, images, etc.)
// Endpoint : GET /api/VmCompaign/guidelines/{guidelineId}/assets
// ─────────────────────────────────────────────────────────

class VmGuidelineAsset {
  final int id;
  final int vmGuidelineId;
  final String? assetType;
  final String url;
  final String fileName;
  final String? description;
  final String storedFileName;
  final int size;

  const VmGuidelineAsset({
    required this.id,
    required this.vmGuidelineId,
    this.assetType,
    required this.url,
    required this.fileName,
    this.description,
    required this.storedFileName,
    required this.size,
  });

  factory VmGuidelineAsset.fromJson(Map<String, dynamic> json) {
    return VmGuidelineAsset(
      id: json['id'] as int,
      vmGuidelineId: json['vmGuidelineId'] as int,
      assetType: json['assetType'] as String?,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      description: json['description'] as String?,
      storedFileName: json['storedFileName'] as String,
      size: json['size'] as int,
    );
  }

  // Helper to get file extension
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  // Helper to check if it's a document type
  bool get isDocument {
    final ext = fileExtension;
    return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'].contains(ext);
  }

  // Helper to check if it's an image
  bool get isImage {
    final ext = fileExtension;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  // Helper to format file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
