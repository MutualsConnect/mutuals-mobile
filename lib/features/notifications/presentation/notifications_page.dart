import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/notification_models.dart';
import '../data/notification_repository.dart';

/// Lista de notificaciones con filtro, paginación y marcar como leídas.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();
  final _items = <AppNotification>[];
  NotificationPriority? _filter;
  int _page = 0;
  bool _last = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Si la lista cabe entera en pantalla no habrá desplazamiento que cargue más.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _last) return;
      if (_scroll.position.maxScrollExtent <= 0) _loadMore();
    });
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .list(priority: _filter);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.content);
        _page = 0;
        _last = page.last;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
      _fillViewport();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _last || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .list(priority: _filter, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.content);
        _page++;
        _last = page.last;
      });
    } on ApiException {
      // Al fallar, el siguiente desplazamiento vuelve a intentarlo.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
      _fillViewport();
    }
  }

  void _setFilter(NotificationPriority? filter) {
    if (_filter == filter) return;
    _filter = filter;
    _load();
  }

  Future<void> _open(AppNotification n) async {
    if (!n.read) {
      final index = _items.indexWhere((e) => e.id == n.id);
      if (index >= 0) setState(() => _items[index] = n.copyWith(read: true));
      try {
        await ref.read(notificationRepositoryProvider).markRead(n.id);
      } on ApiException {
        // Si falla, se marcará como leída la próxima vez que se cargue.
      }
      ref.invalidate(unreadCountProvider);
    }
    final route = n.route;
    if (route != null && mounted) context.push(route);
  }

  Future<void> _markAll() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(read: true);
        }
      });
      ref.invalidate(unreadCountProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.read);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (hasUnread)
            TextButton(onPressed: _markAll, child: const Text('Marcar todas')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: _filter == null,
                  onTap: () => _setFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Importantes',
                  selected: _filter == NotificationPriority.high,
                  onTap: () => _setFilter(NotificationPriority.high),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.peach),
      );
    }
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () async {
        await _load();
        ref.invalidate(unreadCountProvider);
      },
      child: _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                EmptyState(
                  emoji: '🔔',
                  title: 'Sin notificaciones',
                  message: 'Aquí verás invitaciones, confirmaciones y avisos de tus rachas.',
                ),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.peach),
                    ),
                  );
                }
                return _NotificationTile(
                  notification: _items[i],
                  onTap: () => _open(_items[i]),
                );
              },
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.peach,
      backgroundColor: AppColors.peachLight,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      showCheckmark: false,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final n = notification;
    return Material(
      color: n.read
          ? Colors.white.withValues(alpha: 0.6)
          : AppColors.peachLight,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    if (n.body != null && n.body!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.body!,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      timeAgo(n.createdAt),
                      style: text.labelSmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.read)
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5533D),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
