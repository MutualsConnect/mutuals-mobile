import '../../../social/data/models/social_models.dart';

/// Estadísticas de una persona en un periodo (`UserWrappedStats`).
class WrappedStats {
  const WrappedStats({
    this.interactions = 0,
    this.activeDays = 0,
    this.longestStreak = 0,
    this.interactionsByMethod = const {},
    this.topMutualUsername,
    this.topMutualDisplayName,
    this.topMutualInteractions = 0,
    this.challengesCompleted = 0,
    this.gemsEarned = 0,
    this.shieldsGifted = 0,
    this.newMutuals = 0,
  });

  final int interactions;
  final int activeDays;
  final int longestStreak;

  /// Interacciones por método: `MANUAL`, `QR` o `PROXIMITY`.
  final Map<String, int> interactionsByMethod;
  final String? topMutualUsername;
  final String? topMutualDisplayName;
  final int topMutualInteractions;
  final int challengesCompleted;
  final int gemsEarned;
  final int shieldsGifted;
  final int newMutuals;

  factory WrappedStats.fromJson(Map<String, dynamic> json) => WrappedStats(
    interactions: _int(json['interactions']),
    activeDays: _int(json['activeDays']),
    longestStreak: _int(json['longestStreak']),
    interactionsByMethod: _counts(json['interactionsByMethod']),
    topMutualUsername: json['topMutualUsername'] as String?,
    topMutualDisplayName: json['topMutualDisplayName'] as String?,
    topMutualInteractions: _int(json['topMutualInteractions']),
    challengesCompleted: _int(json['challengesCompleted']),
    gemsEarned: _int(json['gemsEarned']),
    shieldsGifted: _int(json['shieldsGifted']),
    newMutuals: _int(json['newMutuals']),
  );

  /// Sin ninguna actividad en el periodo.
  bool get isEmpty =>
      interactions == 0 &&
      activeDays == 0 &&
      newMutuals == 0 &&
      challengesCompleted == 0;
}

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

Map<String, int> _counts(Object? v) => v is Map
    ? v.map((k, n) => MapEntry(k.toString(), (n as num).toInt()))
    : const {};

enum WrappedPeriodType { monthly, yearly, allTime }

/// Un Wrapped ya generado (`WrappedResponse`).
class WrappedSummary {
  const WrappedSummary({
    required this.id,
    required this.periodType,
    required this.periodKey,
    required this.generatedAt,
    required this.stats,
  });

  final int id;
  final WrappedPeriodType periodType;
  final String periodKey;
  final DateTime generatedAt;
  final WrappedStats stats;

  factory WrappedSummary.fromJson(Map<String, dynamic> json) => WrappedSummary(
    id: (json['id'] as num).toInt(),
    periodType: switch (json['periodType']) {
      'YEARLY' => WrappedPeriodType.yearly,
      'ALL_TIME' => WrappedPeriodType.allTime,
      _ => WrappedPeriodType.monthly,
    },
    periodKey: json['periodKey'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    stats: WrappedStats.fromJson(json['stats'] as Map<String, dynamic>),
  );

  /// "Noviembre 2026", "Año 2026" o "Todo el tiempo".
  String get label => wrappedPeriodLabel(periodKey);
}

const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

String wrappedPeriodLabel(String key) {
  if (key == 'ALL') return 'Todo el tiempo';
  if (key.length == 4) return 'Año $key';
  final parts = key.split('-');
  if (parts.length == 2) {
    final month = int.tryParse(parts[1]);
    if (month != null && month >= 1 && month <= 12) {
      return '${_monthNames[month - 1]} ${parts[0]}';
    }
  }
  return key;
}

/// Tu historia con un amigo (`FriendWrappedSection`).
class FriendWrapped {
  const FriendWrapped({
    required this.friend,
    required this.currentlyMutual,
    required this.totalStreaks,
    required this.bestStreak,
    required this.interactions,
    this.challengesCompleted = 0,
  });

  final UserSummary friend;
  final bool currentlyMutual;
  final int totalStreaks;
  final int bestStreak;
  final int interactions;
  final int challengesCompleted;

  factory FriendWrapped.fromJson(Map<String, dynamic> json) => FriendWrapped(
    friend: UserSummary.fromJson(json['friend'] as Map<String, dynamic>),
    currentlyMutual: json['currentlyMutual'] as bool? ?? false,
    totalStreaks: _int(json['totalStreaks']),
    bestStreak: _int(json['bestStreak']),
    interactions: _int(json['interactions']),
    challengesCompleted: _int(json['challengesCompleted']),
  );
}

/// Wrapped de todo el tiempo (`AllTimeWrappedResponse`).
class AllTimeWrapped {
  const AllTimeWrapped({
    required this.overall,
    required this.fullAccess,
    required this.friends,
  });

  final WrappedStats overall;

  /// Plus ve todas las secciones por amigo; el plan gratis solo las primeras.
  final bool fullAccess;
  final List<FriendWrapped> friends;

  factory AllTimeWrapped.fromJson(Map<String, dynamic> json) => AllTimeWrapped(
    overall: WrappedStats.fromJson(json['overall'] as Map<String, dynamic>),
    fullAccess: json['fullAccess'] as bool? ?? false,
    friends: (json['friends'] as List? ?? const [])
        .map((e) => FriendWrapped.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
