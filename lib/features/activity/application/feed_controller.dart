import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/activity_repository.dart';
import '../data/models/activity_models.dart';

class FeedState {
  const FeedState({
    this.items = const [],
    this.page = 0,
    this.last = false,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<Activity> items;
  final int page;
  final bool last;
  final bool loading;
  final bool loadingMore;
  final String? error;

  FeedState copyWith({
    List<Activity>? items,
    int? page,
    bool? last,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) =>
      FeedState(
        items: items ?? this.items,
        page: page ?? this.page,
        last: last ?? this.last,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Feed de novedades: carga por páginas y actualiza likes y comentarios al instante.
class FeedController extends Notifier<FeedState> {
  ActivityRepository get _repo => ref.read(activityRepositoryProvider);

  @override
  FeedState build() {
    Future.microtask(refresh);
    return const FeedState();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repo.feed();
      state = FeedState(items: page.content, page: 0, last: page.last, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || state.last) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.feed(page: state.page + 1);
      state = state.copyWith(
        items: [...state.items, ...page.content],
        page: state.page + 1,
        last: page.last,
        loadingMore: false,
      );
    } on ApiException {
      state = state.copyWith(loadingMore: false);
    }
  }

  void _replace(int id, Activity Function(Activity) change) {
    state = state.copyWith(items: [for (final a in state.items) a.id == id ? change(a) : a]);
  }

  /// Cambia el like al instante y lo revierte si el servidor falla. Devuelve el
  /// mensaje de error, o `null` si salió bien.
  Future<String?> toggleLike(Activity activity) async {
    final liked = !activity.likedByMe;
    _replace(
      activity.id,
      (a) => a.copyWith(likedByMe: liked, likeCount: a.likeCount + (liked ? 1 : -1)),
    );
    try {
      if (liked) {
        await _repo.like(activity.id);
      } else {
        await _repo.unlike(activity.id);
      }
      return null;
    } on ApiException catch (e) {
      _replace(activity.id, (_) => activity);
      return e.message;
    }
  }

  void commentAdded(int activityId) =>
      _replace(activityId, (a) => a.copyWith(commentCount: a.commentCount + 1));
}

final feedControllerProvider = NotifierProvider<FeedController, FeedState>(FeedController.new);
