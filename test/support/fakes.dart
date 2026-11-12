import 'package:dio/dio.dart';
import 'package:mutuals/core/location/location_service.dart';
import 'package:mutuals/core/media/photo_picker.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/core/network/page_response.dart';
import 'package:mutuals/features/activity/data/activity_repository.dart';
import 'package:mutuals/features/activity/data/models/activity_models.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/economy/data/models/economy_models.dart';
import 'package:mutuals/features/gamification/data/gamification_repository.dart';
import 'package:mutuals/features/gamification/data/models/gamification_models.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/interactions/data/models/interaction_models.dart';
import 'package:mutuals/features/notifications/data/models/notification_models.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/social/data/models/social_models.dart';
import 'package:mutuals/features/social/data/profile_repository.dart';
import 'package:mutuals/features/subscription/data/models/subscription_models.dart';
import 'package:mutuals/features/subscription/data/subscription_repository.dart';
import 'package:mutuals/features/wrapped/data/models/wrapped_models.dart';
import 'package:mutuals/features/wrapped/data/wrapped_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/models/streak_models.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';

class FakeSocialRepository extends SocialRepository {
  FakeSocialRepository({
    this.mutualList = const [],
    this.unfollowNeedsConfirm = false,
  }) : super(Dio());

  final List<MutualCard> mutualList;
  final bool unfollowNeedsConfirm;
  bool following = false;
  final unfollowCalls = <bool>[];

  static const luis = UserSummary(
    id: 7,
    username: 'luis',
    displayName: 'Luis Vega',
    personalStreak: 4,
  );

  @override
  Future<PageResponse<UserSummary>> search(
    String query, {
    int page = 0,
  }) async => PageResponse(
    content: query.contains('luis') ? [luis] : [],
    page: 0,
    totalElements: query.contains('luis') ? 1 : 0,
    last: true,
  );

  @override
  Future<List<MutualCard>> mutuals() async => mutualList;

  @override
  Future<PublicProfile> profile(int userId) async => PublicProfile(
    id: userId,
    username: 'luis',
    displayName: 'Luis Vega',
    followedByMe: following,
    followsMe: true,
    followers: 2,
  );

  @override
  Future<FollowResult> follow(int userId) async {
    following = true;
    return const FollowResult(following: true, mutual: true);
  }

  @override
  Future<void> unfollow(int userId, {bool confirmStreakLoss = false}) async {
    unfollowCalls.add(confirmStreakLoss);
    if (unfollowNeedsConfirm && !confirmStreakLoss) {
      throw const ApiException(
        message: 'Hay una racha activa',
        statusCode: 409,
      );
    }
    following = false;
  }
}

/// Repositorio de rachas falso con datos configurables.
class FakeStreakRepository extends StreakRepository {
  FakeStreakRepository({
    this.received = const [],
    this.sent = const [],
    this.detailOf,
  }) : super(Dio());

  List<StreakInvitation> received;
  List<StreakInvitation> sent;
  StreakDetail? detailOf;

  final responded = <(int, bool)>[];
  final invited = <int>[];
  var shieldArmedCalls = 0;

  @override
  Future<List<StreakInvitation>> invitations(InvitationBox box) async =>
      box == InvitationBox.received ? received : sent;

  @override
  Future<StreakInvitation> invite(int friendId) async {
    invited.add(friendId);
    return StreakInvitation(
      id: 1,
      inviter: FakeSocialRepository.luis,
      invitee: FakeSocialRepository.luis,
      status: InvitationStatus.pending,
      createdAt: DateTime(2026, 11, 11),
    );
  }

  @override
  Future<StreakInvitation> respond(
    int invitationId, {
    required bool accept,
  }) async {
    responded.add((invitationId, accept));
    received = [];
    return StreakInvitation(
      id: invitationId,
      inviter: FakeSocialRepository.luis,
      invitee: FakeSocialRepository.luis,
      status: accept ? InvitationStatus.accepted : InvitationStatus.rejected,
      createdAt: DateTime(2026, 11, 11),
    );
  }

  @override
  Future<StreakDetail> detail(int streakId) async => detailOf!;

  @override
  Future<StreakDetail> armShield(int streakId) async {
    shieldArmedCalls++;
    return detailOf!;
  }

  @override
  Future<List<StreakHistory>> history() async => const [];
}

Interaction fakeInteraction({
  int id = 3,
  InteractionStatus status = InteractionStatus.pending,
  String? note,
  int? streakLength,
}) => Interaction(
  id: id,
  streakId: 9,
  initiator: FakeSocialRepository.luis,
  confirmer: const UserSummary(id: 1, username: 'ashly', displayName: 'Ashly'),
  method: InteractionMethod.manual,
  status: status,
  note: note,
  streakLength: streakLength,
);

/// Repositorio de interacciones falso con datos configurables.
class FakeInteractionRepository extends InteractionRepository {
  FakeInteractionRepository({this.pendingList = const [], this.proximity})
    : super(Dio());

  List<Interaction> pendingList;
  ProximityResult? proximity;

  final created = <(int, String?)>[];
  final confirmed = <int>[];
  final rejected = <int>[];
  final scanned = <String>[];
  final proximityCalls = <(int, double, double)>[];

  @override
  Future<List<Interaction>> pending() async => pendingList;

  @override
  Future<Interaction> create(int friendId, {String? note}) async {
    created.add((friendId, note));
    return fakeInteraction(note: note);
  }

  @override
  Future<Interaction> confirm(int id) async {
    confirmed.add(id);
    pendingList = pendingList.where((i) => i.id != id).toList();
    return fakeInteraction(
      id: id,
      status: InteractionStatus.confirmed,
      streakLength: 13,
    );
  }

  @override
  Future<Interaction> reject(int id) async {
    rejected.add(id);
    pendingList = pendingList.where((i) => i.id != id).toList();
    return fakeInteraction(id: id, status: InteractionStatus.rejected);
  }

  @override
  Future<MyQrCode> myQr() async => MyQrCode(
    token: 'token-de-prueba',
    expiresAt: DateTime.now().add(const Duration(seconds: 30)),
  );

  @override
  Future<Interaction> checkInWithQr(String token) async {
    scanned.add(token);
    return fakeInteraction(
      status: InteractionStatus.confirmed,
      streakLength: 5,
    );
  }

  @override
  Future<ProximityResult> checkInByProximity({
    required int friendId,
    required double latitude,
    required double longitude,
  }) async {
    proximityCalls.add((friendId, latitude, longitude));
    return proximity!;
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService({this.error});

  final LocationException? error;

  @override
  Future<Coordinates> current() async {
    if (error != null) throw error!;
    return (latitude: -12.05, longitude: -77.04);
  }
}

AppNotification fakeNotification({
  int id = 1,
  String type = 'STREAK_INVITATION',
  String title = 'Luis quiere empezar una racha contigo',
  bool read = false,
  String? referenceType = 'STREAK_INVITATION',
  int? referenceId = 4,
  NotificationPriority priority = NotificationPriority.high,
}) => AppNotification(
  id: id,
  type: type,
  priority: priority,
  title: title,
  body: 'Acepta y empiecen hoy',
  read: read,
  referenceType: referenceType,
  referenceId: referenceId,
  createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
);

/// Repositorio de notificaciones falso con páginas de 2 elementos.
class FakeNotificationRepository extends NotificationRepository {
  FakeNotificationRepository({List<AppNotification> items = const []})
    : items = List.of(items),
      super(Dio());

  final List<AppNotification> items;
  final read = <int>[];
  var readAllCalls = 0;
  final pagesRequested = <int>[];
  final filtersRequested = <NotificationPriority?>[];

  @override
  Future<PageResponse<AppNotification>> list({
    NotificationPriority? priority,
    int page = 0,
  }) async {
    pagesRequested.add(page);
    filtersRequested.add(priority);
    final filtered = priority == null
        ? items
        : items.where((n) => n.priority == priority).toList();
    const size = 2;
    final start = page * size;
    final end = (start + size).clamp(0, filtered.length);
    return PageResponse(
      content: start >= filtered.length ? [] : filtered.sublist(start, end),
      page: page,
      totalElements: filtered.length,
      last: end >= filtered.length,
    );
  }

  @override
  Future<UnreadCount> unreadCount() async =>
      UnreadCount(total: items.where((n) => !n.read).length);

  @override
  Future<void> markRead(int id) async => read.add(id);

  @override
  Future<void> markAllRead() async => readAllCalls++;
}

WalletTransaction fakeTransaction({
  int id = 1,
  WalletCurrency currency = WalletCurrency.gems,
  int amount = 10,
  WalletTransactionType type = WalletTransactionType.earn,
  String? counterparty,
}) => WalletTransaction(
  id: id,
  currency: currency,
  amount: amount,
  type: type,
  counterpartyUsername: counterparty,
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
);

/// Repositorio de economía falso con saldo y movimientos configurables.
class FakeEconomyRepository extends EconomyRepository {
  FakeEconomyRepository({
    this.gems = 0,
    this.shields = 0,
    this.price = 20,
    List<WalletTransaction> history = const [],
    this.purchaseError,
  }) : history = List.of(history),
       super(Dio());

  int gems;
  int shields;
  final int price;
  final List<WalletTransaction> history;
  final ApiException? purchaseError;

  final purchases = <int>[];
  final gifts = <int>[];

  Wallet get _wallet =>
      Wallet(gems: gems, shields: shields, shieldPriceGems: price);

  @override
  Future<Wallet> wallet() async => _wallet;

  @override
  Future<PageResponse<WalletTransaction>> transactions({int page = 0}) async {
    const size = 2;
    final start = page * size;
    final end = (start + size).clamp(0, history.length);
    return PageResponse(
      content: start >= history.length ? [] : history.sublist(start, end),
      page: page,
      totalElements: history.length,
      last: end >= history.length,
    );
  }

  @override
  Future<Wallet> purchaseShields(int quantity) async {
    if (purchaseError != null) throw purchaseError!;
    purchases.add(quantity);
    gems -= quantity * price;
    shields += quantity;
    history.insert(
      0,
      fakeTransaction(
        id: 99,
        amount: -quantity * price,
        type: WalletTransactionType.spend,
      ),
    );
    return _wallet;
  }

  @override
  Future<Wallet> giftShield(int friendId) async {
    gifts.add(friendId);
    shields -= 1;
    return _wallet;
  }
}

Achievement fakeAchievement({
  String code = 'A',
  String name = 'Logro',
  bool unlocked = false,
  int reward = 5,
}) => Achievement(
  code: code,
  name: name,
  description: 'Descripción de $name',
  type: 'STREAK',
  threshold: 1,
  rewardGems: reward,
  unlocked: unlocked,
  unlockedAt: unlocked ? DateTime(2026, 11, 10) : null,
);

AvatarItem fakeAvatarItem({
  int id = 1,
  String code = 'HAIR_CURLY',
  String name = 'Cabello rizado',
  AvatarLayer layer = AvatarLayer.hair,
  int price = 20,
  bool owned = false,
  bool equipped = false,
  bool premiumOnly = false,
}) => AvatarItem(
  id: id,
  code: code,
  name: name,
  layer: layer,
  priceGems: price,
  owned: owned,
  equipped: equipped,
  premiumOnly: premiumOnly,
);

Challenge fakeChallenge({
  int id = 5,
  bool requiresPhoto = false,
  bool submittedByMe = false,
  ChallengeStatus status = ChallengeStatus.open,
  List<ChallengeSubmission> submissions = const [],
}) => Challenge(
  id: id,
  template: ChallengeTemplate(
    id: 1,
    title: 'Pregunta del día',
    prompt: 'Hazle una pregunta que nunca le hayas hecho',
    type: 'REMOTE',
    rewardGems: 10,
    requiresPhoto: requiresPhoto,
  ),
  friend: FakeSocialRepository.luis,
  weekStart: DateTime(2026, 11, 9),
  status: status,
  submittedByMe: submittedByMe,
  submissions: submissions,
);

/// Repositorio de gamificación falso con datos configurables.
class FakeGamificationRepository extends GamificationRepository {
  FakeGamificationRepository({
    this.achievementList = const [],
    List<AvatarItem> items = const [],
    this.challengeList = const [],
  }) : items = List.of(items),
       super(Dio());

  final List<Achievement> achievementList;
  final List<AvatarItem> items;
  final List<Challenge> challengeList;

  final purchased = <int>[];
  final equipped = <int>[];
  final submissions = <({int id, String? content, String? photo})>[];

  @override
  Future<List<Achievement>> achievements() async => achievementList;

  @override
  Future<List<AvatarItem>> avatarItems() async => List.of(items);

  @override
  Future<AvatarItem> purchaseAvatarItem(int itemId) async {
    purchased.add(itemId);
    final i = items.indexWhere((e) => e.id == itemId);
    items[i] = items[i].copyWith(owned: true);
    return items[i];
  }

  @override
  Future<AvatarItem> equipAvatarItem(int itemId) async {
    equipped.add(itemId);
    final target = items.firstWhere((e) => e.id == itemId);
    for (var i = 0; i < items.length; i++) {
      if (items[i].layer == target.layer) {
        items[i] = items[i].copyWith(equipped: items[i].id == itemId);
      }
    }
    return items.firstWhere((e) => e.id == itemId);
  }

  @override
  Future<List<Challenge>> challenges() async => challengeList;

  @override
  Future<Challenge> challenge(int id) async =>
      challengeList.firstWhere((c) => c.id == id);

  @override
  Future<Challenge> submitChallenge(
    int id, {
    String? content,
    String? photoPath,
  }) async {
    submissions.add((id: id, content: content, photo: photoPath));
    return challengeList.firstWhere((c) => c.id == id);
  }
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker(this.path);

  final String? path;

  @override
  Future<String?> pick() async => path;
}

Activity fakeActivity({
  int id = 1,
  String title = 'Luis desbloqueó Primer fueguito',
  String type = 'ACHIEVEMENT_UNLOCKED',
  int likes = 0,
  int comments = 0,
  bool liked = false,
  bool fromMutual = true,
  bool canComment = true,
}) => Activity(
  id: id,
  actor: FakeSocialRepository.luis,
  type: type,
  title: title,
  likeCount: likes,
  commentCount: comments,
  likedByMe: liked,
  fromMutual: fromMutual,
  canComment: canComment,
  createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
);

ActivityComment fakeComment({int id = 1, String content = '¡Felicidades!'}) =>
    ActivityComment(
      id: id,
      author: FakeSocialRepository.luis,
      content: content,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );

/// Repositorio del feed falso con páginas de 2 novedades.
class FakeActivityRepository extends ActivityRepository {
  FakeActivityRepository({
    this.items = const [],
    List<ActivityComment> comments = const [],
    this.likeError,
  }) : commentList = List.of(comments),
       super(Dio());

  final List<Activity> items;
  final List<ActivityComment> commentList;
  final ApiException? likeError;

  final liked = <int>[];
  final unliked = <int>[];
  final sentComments = <(int, String)>[];
  final feedPages = <int>[];

  @override
  Future<PageResponse<Activity>> feed({int page = 0}) async {
    feedPages.add(page);
    const size = 2;
    final start = page * size;
    final end = (start + size).clamp(0, items.length);
    return PageResponse(
      content: start >= items.length ? [] : items.sublist(start, end),
      page: page,
      totalElements: items.length,
      last: end >= items.length,
    );
  }

  @override
  Future<Activity> like(int id) async {
    if (likeError != null) throw likeError!;
    liked.add(id);
    return items.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> unlike(int id) async {
    if (likeError != null) throw likeError!;
    unliked.add(id);
  }

  @override
  Future<PageResponse<ActivityComment>> comments(
    int id, {
    int page = 0,
  }) async => PageResponse(
    content: commentList,
    page: 0,
    totalElements: commentList.length,
    last: true,
  );

  @override
  Future<ActivityComment> comment(int id, String content) async {
    sentComments.add((id, content));
    final c = fakeComment(id: 100 + sentComments.length, content: content);
    commentList.add(c);
    return c;
  }
}

WrappedSummary fakeWrapped({
  String key = '2026-10',
  WrappedPeriodType type = WrappedPeriodType.monthly,
  WrappedStats stats = const WrappedStats(
    interactions: 42,
    activeDays: 12,
    longestStreak: 9,
    interactionsByMethod: {'QR': 30, 'MANUAL': 12},
    topMutualDisplayName: 'Luis Vega',
    topMutualInteractions: 25,
    challengesCompleted: 2,
    gemsEarned: 40,
    newMutuals: 3,
  ),
}) => WrappedSummary(
  id: 1,
  periodType: type,
  periodKey: key,
  generatedAt: DateTime(2026, 11, 1),
  stats: stats,
);

/// Repositorio de Wrapped falso.
class FakeWrappedRepository extends WrappedRepository {
  FakeWrappedRepository({this.items = const [], AllTimeWrapped? allTime})
    : _allTime =
          allTime ??
          const AllTimeWrapped(
            overall: WrappedStats(),
            fullAccess: false,
            friends: [],
          ),
      super(Dio());

  final List<WrappedSummary> items;
  final AllTimeWrapped _allTime;

  @override
  Future<List<WrappedSummary>> mine() async => items;

  @override
  Future<AllTimeWrapped> allTime() async => _allTime;
}

Subscription fakeSubscription({
  SubscriptionPlan plan = SubscriptionPlan.free,
  SubscriptionStatus status = SubscriptionStatus.active,
}) => Subscription(
  plan: plan,
  status: status,
  expiresAt: plan == SubscriptionPlan.plus ? DateTime(2026, 12, 12) : null,
  maxActiveStreaks: plan == SubscriptionPlan.plus ? 2147483647 : 4,
  benefits: plan == SubscriptionPlan.plus
      ? const ['Unlimited active streaks', '1 free shield every month']
      : const ['Up to 4 active streaks'],
);

/// Repositorio de suscripción falso que cambia de plan al suscribirse o cancelar.
class FakeSubscriptionRepository extends SubscriptionRepository {
  FakeSubscriptionRepository([Subscription? initial])
    : sub = initial ?? fakeSubscription(),
      super(Dio());

  Subscription sub;
  final subscribed = <BillingPeriod>[];
  var cancelCalls = 0;

  @override
  Future<Subscription> current() async => sub;

  @override
  Future<Subscription> subscribe(BillingPeriod period) async {
    subscribed.add(period);
    return sub = fakeSubscription(plan: SubscriptionPlan.plus);
  }

  @override
  Future<Subscription> cancel() async {
    cancelCalls++;
    return sub = fakeSubscription(
      plan: SubscriptionPlan.plus,
      status: SubscriptionStatus.canceled,
    );
  }
}

/// Repositorio de perfil, bloqueos y reportes falso.
class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({this.error}) : super(Dio());

  final ApiException? error;
  final updates = <({String name, String bio})>[];
  final blocked = <int>[];
  final reports = <({int id, ReportReason reason, String? description})>[];

  @override
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) async {
    if (error != null) throw error!;
    updates.add((name: displayName.trim(), bio: bio.trim()));
  }

  @override
  Future<void> block(int userId) async => blocked.add(userId);

  @override
  Future<void> report(
    int userId,
    ReportReason reason, {
    String? description,
  }) async =>
      reports.add((id: userId, reason: reason, description: description));
}
