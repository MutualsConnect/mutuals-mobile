import '../../../social/data/models/social_models.dart';

/// Una novedad del feed (`ActivityResponse`).
class Activity {
  const Activity({
    required this.id,
    required this.actor,
    required this.type,
    required this.title,
    required this.createdAt,
    this.value,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.fromMutual = false,
    this.canComment = false,
  });

  final int id;
  final UserSummary actor;

  /// `STREAK_MILESTONE`, `PERSONAL_STREAK_MILESTONE`, `ACHIEVEMENT_UNLOCKED`,
  /// `RECORD_BROKEN` o `CHALLENGE_COMPLETED`.
  final String type;
  final String title;
  final int? value;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool fromMutual;

  /// Solo los mutuals pueden comentar.
  final bool canComment;
  final DateTime createdAt;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: (json['id'] as num).toInt(),
    actor: UserSummary.fromJson(json['actor'] as Map<String, dynamic>),
    type: json['type'] as String,
    title: json['title'] as String,
    value: (json['value'] as num?)?.toInt(),
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    likedByMe: json['likedByMe'] as bool? ?? false,
    fromMutual: json['fromMutual'] as bool? ?? false,
    canComment: json['canComment'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Activity copyWith({int? likeCount, int? commentCount, bool? likedByMe}) =>
      Activity(
        id: id,
        actor: actor,
        type: type,
        title: title,
        value: value,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
        fromMutual: fromMutual,
        canComment: canComment,
        createdAt: createdAt,
      );

  String get emoji => switch (type) {
    'STREAK_MILESTONE' => '🔥',
    'PERSONAL_STREAK_MILESTONE' => '⚡',
    'ACHIEVEMENT_UNLOCKED' => '🏅',
    'RECORD_BROKEN' => '🏆',
    'CHALLENGE_COMPLETED' => '🎯',
    _ => '✨',
  };
}

/// Un comentario (`CommentResponse`).
class ActivityComment {
  const ActivityComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final UserSummary author;
  final String content;
  final DateTime createdAt;

  factory ActivityComment.fromJson(Map<String, dynamic> json) =>
      ActivityComment(
        id: (json['id'] as num).toInt(),
        author: UserSummary.fromJson(json['author'] as Map<String, dynamic>),
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
