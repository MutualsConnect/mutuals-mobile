import '../../../social/data/models/social_models.dart';

/// Logro del catálogo con tu progreso (`AchievementResponse`).
class Achievement {
  const Achievement({
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.threshold,
    required this.rewardGems,
    this.unlocked = false,
    this.unlockedAt,
  });

  final String code;
  final String name;
  final String description;

  /// `STREAK`, `PERSONAL_STREAK`, `MONTHLY_MEDAL`, `CHALLENGE` o `SOCIAL`.
  final String type;
  final int threshold;
  final int rewardGems;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    type: json['type'] as String,
    threshold: (json['threshold'] as num?)?.toInt() ?? 0,
    rewardGems: (json['rewardGems'] as num?)?.toInt() ?? 0,
    unlocked: json['unlocked'] as bool? ?? false,
    unlockedAt: json['unlockedAt'] == null
        ? null
        : DateTime.parse(json['unlockedAt'] as String),
  );

  String get emoji => switch (type) {
    'STREAK' => '🔥',
    'PERSONAL_STREAK' => '⚡',
    'MONTHLY_MEDAL' => '🏅',
    'CHALLENGE' => '🎯',
    'SOCIAL' => '🤝',
    _ => '🏆',
  };
}

enum AvatarLayer { base, hair, outfit, accessory }

AvatarLayer _layer(String raw) => switch (raw) {
  'HAIR' => AvatarLayer.hair,
  'OUTFIT' => AvatarLayer.outfit,
  'ACCESSORY' => AvatarLayer.accessory,
  _ => AvatarLayer.base,
};

/// Ítem de la tienda de avatares (`AvatarItemResponse`).
class AvatarItem {
  const AvatarItem({
    required this.id,
    required this.code,
    required this.name,
    required this.layer,
    required this.priceGems,
    this.premiumOnly = false,
    this.unlockAchievementCode,
    this.imageUrl,
    this.owned = false,
    this.equipped = false,
  });

  final int id;
  final String code;
  final String name;
  final AvatarLayer layer;
  final int priceGems;
  final bool premiumOnly;
  final String? unlockAchievementCode;
  final String? imageUrl;
  final bool owned;
  final bool equipped;

  factory AvatarItem.fromJson(Map<String, dynamic> json) => AvatarItem(
    id: (json['id'] as num).toInt(),
    code: json['code'] as String,
    name: json['name'] as String,
    layer: _layer(json['layer'] as String),
    priceGems: (json['priceGems'] as num?)?.toInt() ?? 0,
    premiumOnly: json['premiumOnly'] as bool? ?? false,
    unlockAchievementCode: json['unlockAchievementCode'] as String?,
    imageUrl: json['imageUrl'] as String?,
    owned: json['owned'] as bool? ?? false,
    equipped: json['equipped'] as bool? ?? false,
  );

  /// El backend aún no trae imágenes, así que cada ítem se representa con un emoji.
  String get emoji => switch (code) {
    'HAIR_CURLY' => '👩‍🦱',
    'HAIR_BUZZ' => '💈',
    'OUTFIT_HOODIE' => '🧥',
    'OUTFIT_UTEC' => '👕',
    'ACCESSORY_CAP' => '🧢',
    _ => switch (layer) {
      AvatarLayer.base => '🙂',
      AvatarLayer.hair => '💇',
      AvatarLayer.outfit => '👕',
      AvatarLayer.accessory => '🎩',
    },
  };

  AvatarItem copyWith({bool? owned, bool? equipped}) => AvatarItem(
    id: id,
    code: code,
    name: name,
    layer: layer,
    priceGems: priceGems,
    premiumOnly: premiumOnly,
    unlockAchievementCode: unlockAchievementCode,
    imageUrl: imageUrl,
    owned: owned ?? this.owned,
    equipped: equipped ?? this.equipped,
  );
}

enum ChallengeStatus { open, completed, expired }

/// Plantilla del desafío semanal (`ChallengeTemplateResponse`).
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.id,
    required this.title,
    required this.prompt,
    required this.type,
    required this.rewardGems,
    this.requiresPresence = false,
    this.requiresPhoto = false,
  });

  final int id;
  final String title;
  final String prompt;

  /// `REMOTE`, `IN_PERSON` o `CREATIVE`.
  final String type;
  final int rewardGems;
  final bool requiresPresence;
  final bool requiresPhoto;

  factory ChallengeTemplate.fromJson(Map<String, dynamic> json) =>
      ChallengeTemplate(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        prompt: json['prompt'] as String? ?? '',
        type: json['type'] as String? ?? 'REMOTE',
        rewardGems: (json['rewardGems'] as num?)?.toInt() ?? 0,
        requiresPresence: json['requiresPresence'] as bool? ?? false,
        requiresPhoto: json['requiresPhoto'] as bool? ?? false,
      );

  String get emoji => switch (type) {
    'IN_PERSON' => '📍',
    'CREATIVE' => '🎨',
    _ => '📱',
  };
}

/// La respuesta de uno de los dos al desafío (`SubmissionResponse`).
class ChallengeSubmission {
  const ChallengeSubmission({
    required this.user,
    required this.revealed,
    this.content,
    this.photoUrl,
  });

  final UserSummary user;

  /// Es `false` hasta que ambos cumplen: entonces se ve la respuesta del otro.
  final bool revealed;
  final String? content;
  final String? photoUrl;

  factory ChallengeSubmission.fromJson(Map<String, dynamic> json) =>
      ChallengeSubmission(
        user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
        revealed: json['revealed'] as bool? ?? false,
        content: json['content'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );
}

/// Desafío de la semana con un mutual (`ChallengeResponse`).
class Challenge {
  const Challenge({
    required this.id,
    required this.template,
    required this.friend,
    required this.weekStart,
    required this.status,
    required this.submittedByMe,
    this.submissions = const [],
  });

  final int id;
  final ChallengeTemplate template;
  final UserSummary friend;
  final DateTime weekStart;
  final ChallengeStatus status;
  final bool submittedByMe;
  final List<ChallengeSubmission> submissions;

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: (json['id'] as num).toInt(),
    template: ChallengeTemplate.fromJson(
      json['template'] as Map<String, dynamic>,
    ),
    friend: UserSummary.fromJson(json['friend'] as Map<String, dynamic>),
    weekStart: DateTime.parse(json['weekStart'] as String),
    status: switch (json['status']) {
      'COMPLETED' => ChallengeStatus.completed,
      'EXPIRED' => ChallengeStatus.expired,
      _ => ChallengeStatus.open,
    },
    submittedByMe: json['submittedByMe'] as bool? ?? false,
    submissions: (json['submissions'] as List? ?? const [])
        .map((e) => ChallengeSubmission.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
