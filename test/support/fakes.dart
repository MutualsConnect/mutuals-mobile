import 'package:dio/dio.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/core/network/page_response.dart';
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
