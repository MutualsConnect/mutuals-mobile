/// Datos del usuario autenticado (`MeResponse` del backend).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.roles = const [],
    this.gems = 0,
    this.shields = 0,
    this.personalStreak = 0,
    this.longestPersonalStreak = 0,
    this.premium = false,
    this.onboardingCompleted = false,
  });

  final int id;
  final String email;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final List<String> roles;
  final int gems;
  final int shields;
  final int personalStreak;
  final int longestPersonalStreak;
  final bool premium;
  final bool onboardingCompleted;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        roles: (json['roles'] as List? ?? const []).cast<String>(),
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        shields: (json['shields'] as num?)?.toInt() ?? 0,
        personalStreak: (json['personalStreak'] as num?)?.toInt() ?? 0,
        longestPersonalStreak:
            (json['longestPersonalStreak'] as num?)?.toInt() ?? 0,
        premium: json['premium'] as bool? ?? false,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      );
}
