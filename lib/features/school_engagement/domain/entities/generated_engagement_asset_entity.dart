enum EngagementAssetType { image, pdf, printReady }

class GeneratedEngagementAssetEntity {
  final EngagementAssetType assetType;

  final String fileName;
  final String filePath;

  final String mimeType;

  final int? width;
  final int? height;

  final int fileSizeBytes;

  final DateTime generatedAt;

  const GeneratedEngagementAssetEntity({
    required this.assetType,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    this.width,
    this.height,
    required this.fileSizeBytes,
    required this.generatedAt,
  });

  bool get isImage => assetType == EngagementAssetType.image;

  bool get isPdf => assetType == EngagementAssetType.pdf;

  bool get isPrintReady => assetType == EngagementAssetType.printReady;

  bool get hasDimensions => width != null && height != null;

  GeneratedEngagementAssetEntity copyWith({
    EngagementAssetType? assetType,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? width,
    int? height,
    int? fileSizeBytes,
    DateTime? generatedAt,
  }) {
    return GeneratedEngagementAssetEntity(
      assetType: assetType ?? this.assetType,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
