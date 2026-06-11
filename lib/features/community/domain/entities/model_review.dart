class ModelReview {
  final String id;
  final String modelId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final int likesCount;
  final List<String> likedUsers;
  final DateTime createdAt;

  const ModelReview({
    required this.id,
    required this.modelId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.likesCount = 0,
    this.likedUsers = const [],
    required this.createdAt,
  });

  ModelReview copyWith({
    int? likesCount,
    List<String>? likedUsers,
    String? comment,
    double? rating,
  }) {
    return ModelReview(
      id: id,
      modelId: modelId,
      userId: userId,
      userName: userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      likesCount: likesCount ?? this.likesCount,
      likedUsers: likedUsers ?? this.likedUsers,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modelId': modelId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'likesCount': likesCount,
      'likedUsers': likedUsers,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ModelReview.fromMap(Map<dynamic, dynamic> map) {
    return ModelReview(
      id: map['id'] as String? ?? '',
      modelId: map['modelId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous User',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      likesCount: map['likesCount'] as int? ?? 0,
      likedUsers: (map['likedUsers'] as List?)?.cast<String>() ?? const [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }
}
