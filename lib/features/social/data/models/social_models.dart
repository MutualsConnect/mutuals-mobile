/// Resumen de un usuario (`UserSummaryResponse`).
class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.personalStreak = 0,
  });

  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int personalStreak;

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        personalStreak: (json['personalStreak'] as num?)?.toInt() ?? 0,
      );
}

/// Perfil público de otro usuario (`PublicProfileResponse`).
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.personalStreak = 0,
    this.longestPersonalStreak = 0,
    this.followers = 0,
    this.following = 0,
    this.achievements = 0,
    this.followedByMe = false,
    this.followsMe = false,
    this.premium = false,
  });

  final int id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int personalStreak;
  final int longestPersonalStreak;
  final int followers;
  final int following;
  final int achievements;
  final bool followedByMe;
  final bool followsMe;
  final bool premium;

  /// Se siguen mutuamente.
  bool get isMutual => followedByMe && followsMe;

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        personalStreak: (json['personalStreak'] as num?)?.toInt() ?? 0,
        longestPersonalStreak: (json['longestPersonalStreak'] as num?)?.toInt() ?? 0,
        followers: (json['followers'] as num?)?.toInt() ?? 0,
        following: (json['following'] as num?)?.toInt() ?? 0,
        achievements: (json['achievements'] as num?)?.toInt() ?? 0,
        followedByMe: json['followedByMe'] as bool? ?? false,
        followsMe: json['followsMe'] as bool? ?? false,
        premium: json['premium'] as bool? ?? false,
      );
}

/// Resumen de una racha (`StreakCardResponse`).
class StreakCard {
  const StreakCard({
    required this.id,
    required this.currentLength,
    this.countedToday = false,
    this.atRisk = false,
    this.shieldArmed = false,
  });

  final int id;
  final int currentLength;
  final bool countedToday;
  final bool atRisk;
  final bool shieldArmed;

  factory StreakCard.fromJson(Map<String, dynamic> json) => StreakCard(
        id: (json['id'] as num).toInt(),
        currentLength: (json['currentLength'] as num).toInt(),
        countedToday: json['countedToday'] as bool? ?? false,
        atRisk: json['atRisk'] as bool? ?? false,
        shieldArmed: json['shieldArmed'] as bool? ?? false,
      );
}

/// Un mutual: amigo con el que te sigues mutuamente (`MutualCardResponse`).
class MutualCard {
  const MutualCard({
    required this.mutualId,
    required this.friend,
    this.streak,
    this.invitationPending = false,
  });

  final int mutualId;
  final UserSummary friend;
  final StreakCard? streak;
  final bool invitationPending;

  factory MutualCard.fromJson(Map<String, dynamic> json) => MutualCard(
        mutualId: (json['mutualId'] as num).toInt(),
        friend: UserSummary.fromJson(json['friend'] as Map<String, dynamic>),
        streak: json['streak'] == null
            ? null
            : StreakCard.fromJson(json['streak'] as Map<String, dynamic>),
        invitationPending: json['invitationPending'] as bool? ?? false,
      );
}

/// Resultado de seguir a alguien (`FollowResponse`).
class FollowResult {
  const FollowResult({required this.following, required this.mutual});

  final bool following;
  final bool mutual;

  factory FollowResult.fromJson(Map<String, dynamic> json) => FollowResult(
        following: json['following'] as bool,
        mutual: json['mutual'] as bool,
      );
}
