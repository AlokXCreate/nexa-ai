class CommunityModel {
  final String id;
  final String name;
  final String family;
  final String developerId;
  final String developerName;
  final String description;
  final String category;
  final String parameters;
  final String quantization;
  final String downloadSize;
  final String installedSize;
  final String ramRequirement;
  final String downloadUrl;
  final String checksum;
  final double rating;
  final int downloadsCount;
  final int reviewsCount;
  final DateTime createdAt;
  final bool isEditorChoice;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.family,
    required this.developerId,
    required this.developerName,
    required this.description,
    required this.category,
    required this.parameters,
    required this.quantization,
    required this.downloadSize,
    required this.installedSize,
    required this.ramRequirement,
    required this.downloadUrl,
    required this.checksum,
    this.rating = 0.0,
    this.downloadsCount = 0,
    this.reviewsCount = 0,
    required this.createdAt,
    this.isEditorChoice = false,
  });

  CommunityModel copyWith({
    String? name,
    String? family,
    String? description,
    String? category,
    String? parameters,
    String? quantization,
    String? downloadSize,
    String? installedSize,
    String? ramRequirement,
    String? downloadUrl,
    String? checksum,
    double? rating,
    int? downloadsCount,
    int? reviewsCount,
    bool? isEditorChoice,
  }) {
    return CommunityModel(
      id: id,
      name: name ?? this.name,
      family: family ?? this.family,
      developerId: developerId,
      developerName: developerName,
      description: description ?? this.description,
      category: category ?? this.category,
      parameters: parameters ?? this.parameters,
      quantization: quantization ?? this.quantization,
      downloadSize: downloadSize ?? this.downloadSize,
      installedSize: installedSize ?? this.installedSize,
      ramRequirement: ramRequirement ?? this.ramRequirement,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      checksum: checksum ?? this.checksum,
      rating: rating ?? this.rating,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt,
      isEditorChoice: isEditorChoice ?? this.isEditorChoice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'family': family,
      'developerId': developerId,
      'developerName': developerName,
      'description': description,
      'category': category,
      'parameters': parameters,
      'quantization': quantization,
      'downloadSize': downloadSize,
      'installedSize': installedSize,
      'ramRequirement': ramRequirement,
      'downloadUrl': downloadUrl,
      'checksum': checksum,
      'rating': rating,
      'downloadsCount': downloadsCount,
      'reviewsCount': reviewsCount,
      'createdAt': createdAt.toIso8601String(),
      'isEditorChoice': isEditorChoice,
    };
  }

  factory CommunityModel.fromMap(Map<dynamic, dynamic> map) {
    return CommunityModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      family: map['family'] as String? ?? '',
      developerId: map['developerId'] as String? ?? '',
      developerName: map['developerName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Chat',
      parameters: map['parameters'] as String? ?? '',
      quantization: map['quantization'] as String? ?? '',
      downloadSize: map['downloadSize'] as String? ?? '0.0 GB',
      installedSize: map['installedSize'] as String? ?? '0.0 GB',
      ramRequirement: map['ramRequirement'] as String? ?? '4 GB',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      checksum: map['checksum'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      downloadsCount: map['downloadsCount'] as int? ?? 0,
      reviewsCount: map['reviewsCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      isEditorChoice: map['isEditorChoice'] as bool? ?? false,
    );
  }
}
