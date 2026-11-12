import 'package:dio/dio.dart';
import 'package:mutuals/core/location/location_service.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/core/network/page_response.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/interactions/data/models/interaction_models.dart';
import 'package:mutuals/features/social/data/models/social_models.dart';
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
