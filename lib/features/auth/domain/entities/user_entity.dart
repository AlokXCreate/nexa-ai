class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isGuest;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
    required this.isGuest,
  });

  factory UserEntity.guest() {
    return const UserEntity(
      id: 'guest_user',
      email: 'guest@localmind.ai',
      displayName: 'Guest User',
      isEmailVerified: true,
      isGuest: true,
    );
  }
}
