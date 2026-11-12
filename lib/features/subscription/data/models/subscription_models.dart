enum SubscriptionPlan { free, plus }

enum SubscriptionStatus { active, canceled, expired }

enum BillingPeriod { monthly, yearly }

/// Plan actual y beneficios (`SubscriptionResponse`).
class Subscription {
  const Subscription({
    required this.plan,
    required this.status,
    required this.maxActiveStreaks,
    required this.benefits,
    this.startedAt,
    this.expiresAt,
  });

  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  /// Rachas activas permitidas; con Plus no hay límite.
  final int maxActiveStreaks;
  final List<String> benefits;

  bool get isPlus =>
      plan == SubscriptionPlan.plus && status != SubscriptionStatus.expired;

  /// Cancelada: los beneficios siguen hasta el vencimiento.
  bool get isCanceled =>
      plan == SubscriptionPlan.plus && status == SubscriptionStatus.canceled;

  bool get unlimitedStreaks => maxActiveStreaks >= 1000000;

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    plan: json['plan'] == 'PLUS'
        ? SubscriptionPlan.plus
        : SubscriptionPlan.free,
    status: switch (json['status']) {
      'CANCELED' => SubscriptionStatus.canceled,
      'EXPIRED' => SubscriptionStatus.expired,
      _ => SubscriptionStatus.active,
    },
    startedAt: json['startedAt'] == null
        ? null
        : DateTime.parse(json['startedAt'] as String),
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
    maxActiveStreaks: (json['maxActiveStreaks'] as num?)?.toInt() ?? 4,
    benefits: (json['benefits'] as List? ?? const []).cast<String>(),
  );
}

const _benefitTranslations = {
  'Unlimited followers and mutuals': 'Seguidores y mutuals ilimitados',
  'Up to 4 active streaks': 'Hasta 4 rachas activas',
  'Monthly and yearly Wrapped': 'Wrapped mensual y anual',
  'Unlimited active streaks': 'Rachas activas ilimitadas',
  '1 free shield every month': '1 escudo gratis cada mes',
  'Recover a broken streak once a month':
      'Recupera una racha rota una vez al mes',
  'Full all-time Wrapped by friend': 'Wrapped histórico completo por amigo',
  'Exclusive avatar items': 'Ítems de avatar exclusivos',
  'Profile themes, banner, fire styles and app icons':
      'Temas de perfil, banner, estilos de fuego e íconos',
  'Home screen widgets': 'Widgets para la pantalla de inicio',
};

/// El backend envía los beneficios en inglés; los mostramos en español.
String translateBenefit(String benefit) =>
    _benefitTranslations[benefit] ?? benefit;

/// Beneficios de Mutuals Plus, para mostrarlos a quien aún tiene el plan gratis.
const plusBenefits = [
  'Rachas activas ilimitadas',
  '1 escudo gratis cada mes',
  'Recupera una racha rota una vez al mes',
  'Wrapped histórico completo por amigo',
  'Ítems de avatar exclusivos',
  'Temas de perfil, banner, estilos de fuego e íconos',
  'Widgets para la pantalla de inicio',
];
