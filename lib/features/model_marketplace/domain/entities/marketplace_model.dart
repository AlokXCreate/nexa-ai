class MarketplaceModel {
  final String id;
  final String name;
  final String family;
  final String developer;
  final String description;
  final String category; // Chat, Coding, Reasoning, Writing, Translation, Vision
  final String parameters;
  final String quantization;
  final String downloadSize; // maps to download_size
  final String installedSize; // maps to installed_size
  final String ramRequirement; // maps to ram_requirement
  final String minimumAndroidVersion; // maps to minimum_android_version
  final String version;
  final String releaseDate; // maps to release_date
  final List<String> languages;
  final String license;
  final double rating;
  final String downloads;
  final String thumbnail;
  final String banner;
  final List<String> tags;
  final String downloadUrl; // maps to download_url
  final String checksum;
  final bool isDownloaded; // local state tracker

  // Backward compatibility getter
  String get logo => thumbnail;

  const MarketplaceModel({
    required this.id,
    required this.name,
    required this.family,
    required this.developer,
    required this.description,
    required this.category,
    required this.parameters,
    required this.quantization,
    required this.downloadSize,
    required this.installedSize,
    required this.ramRequirement,
    required this.minimumAndroidVersion,
    required this.version,
    required this.releaseDate,
    required this.languages,
    required this.license,
    required this.rating,
    required this.downloads,
    required this.thumbnail,
    required this.banner,
    required this.tags,
    required this.downloadUrl,
    required this.checksum,
    this.isDownloaded = false,
  });

  MarketplaceModel copyWith({
    bool? isDownloaded,
  }) {
    return MarketplaceModel(
      id: id,
      name: name,
      family: family,
      developer: developer,
      description: description,
      category: category,
      parameters: parameters,
      quantization: quantization,
      downloadSize: downloadSize,
      installedSize: installedSize,
      ramRequirement: ramRequirement,
      minimumAndroidVersion: minimumAndroidVersion,
      version: version,
      releaseDate: releaseDate,
      languages: languages,
      license: license,
      rating: rating,
      downloads: downloads,
      thumbnail: thumbnail,
      banner: banner,
      tags: tags,
      downloadUrl: downloadUrl,
      checksum: checksum,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'family': family,
      'developer': developer,
      'description': description,
      'category': category,
      'parameters': parameters,
      'quantization': quantization,
      'download_size': downloadSize,
      'installed_size': installedSize,
      'ram_requirement': ramRequirement,
      'minimum_android_version': minimumAndroidVersion,
      'version': version,
      'release_date': releaseDate,
      'languages': languages,
      'license': license,
      'rating': rating,
      'downloads': downloads,
      'thumbnail': thumbnail,
      'banner': banner,
      'tags': tags,
      'download_url': downloadUrl,
      'checksum': checksum,
    };
  }

  factory MarketplaceModel.fromMap(Map<dynamic, dynamic> map) {
    return MarketplaceModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      family: map['family'] as String? ?? '',
      developer: map['developer'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Chat',
      parameters: map['parameters'] as String? ?? '',
      quantization: map['quantization'] as String? ?? '',
      downloadSize: (map['download_size'] ?? map['downloadSize']) as String? ?? '0.0 GB',
      installedSize: (map['installed_size'] ?? map['installedSize']) as String? ?? '0.0 GB',
      ramRequirement: (map['ram_requirement'] ?? map['ramRequirement']) as String? ?? '4 GB',
      minimumAndroidVersion: (map['minimum_android_version'] ?? map['minimumAndroidVersion']) as String? ?? '7.0',
      version: map['version'] as String? ?? '1.0.0',
      releaseDate: (map['release_date'] ?? map['releaseDate']) as String? ?? '',
      languages: (map['languages'] as List?)?.map((e) => e as String).toList() ?? [],
      license: map['license'] as String? ?? 'Apache-2.0',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.0,
      downloads: map['downloads'] as String? ?? '0K',
      thumbnail: map['thumbnail'] as String? ?? '',
      banner: map['banner'] as String? ?? '',
      tags: (map['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      downloadUrl: (map['download_url'] ?? map['downloadUrl']) as String? ?? '',
      checksum: map['checksum'] as String? ?? '',
      isDownloaded: false,
    );
  }
}
