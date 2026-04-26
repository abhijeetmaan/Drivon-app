class UserProfile {
  final String name;
  final String email;
  final String? phone;
  final String? avatarPath;

  const UserProfile({
    required this.name,
    required this.email,
    this.phone,
    this.avatarPath,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

