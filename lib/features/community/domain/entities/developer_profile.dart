class DeveloperProfile {
  final String id;
  final String name;
  final String bio;
  final String avatarUrl;
  final List<String> followers;
  final int followersCount;
  final int modelsCount;
  final DateTime createdAt;

  const DeveloperProfile({
    required this.id,
    required this.name,
    required this.bio,
    required this.avatarUrl,
    this.followers = const [],
    this.followersCount = 0,
    this.modelsCount = 0,
    required this.createdAt,
  });

  DeveloperProfile copyWith({
    String? name,
    String? bio,
    String? avatarUrl,
    List<String>? followers,
    int? followersCount,
    int? modelsCount,
  }) {
    return DeveloperProfile(
      id: id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followers: followers ?? this.followers,
      followersCount: followersCount ?? this.followersCount,
      modelsCount: modelsCount ?? this.modelsCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'followers': followers,
      'followersCount': followersCount,
      'modelsCount': modelsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeveloperProfile.fromMap(Map<dynamic, dynamic> map) {
    return DeveloperProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Developer',
      bio: map['bio'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      followers: (map['followers'] as List?)?.cast<String>() ?? const [],
      followersCount: map['followersCount'] as int? ?? 0,
      modelsCount: map['modelsCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }
}
