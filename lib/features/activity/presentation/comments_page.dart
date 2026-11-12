import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../application/feed_controller.dart';
import '../data/activity_repository.dart';
import '../data/models/activity_models.dart';

/// Comentarios de una novedad. Solo los mutuals pueden escribir.
class CommentsPage extends ConsumerStatefulWidget {
  const CommentsPage({super.key, required this.activity});

  final Activity activity;

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  final _comments = <ActivityComment>[];
  final _input = TextEditingController();
  int _page = 0;
  bool _last = true;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(activityRepositoryProvider)
          .comments(widget.activity.id, page: more ? _page + 1 : 0);
      if (!mounted) return;
      setState(() {
        if (!more) {
          _comments.clear();
        }
        _comments.addAll(page.content);
        _page = page.page;
        _last = page.last;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final content = _input.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await ref
          .read(activityRepositoryProvider)
          .comment(widget.activity.id, content);
      if (!mounted) return;
      setState(() => _comments.add(comment));
      _input.clear();
      ref
          .read(feedControllerProvider.notifier)
          .commentAdded(widget.activity.id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.peachLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${a.emoji}  ${a.title}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(child: _list()),
          _composer(a),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading && _comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.peach),
      );
    }
    if (_error != null && _comments.isEmpty) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_comments.isEmpty) {
      return const EmptyState(
        emoji: '💬',
        title: 'Sin comentarios',
        message: 'Sé la primera persona en comentar.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      children: [
        for (final c in _comments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: UserAvatar(
              name: c.author.displayName,
              url: c.author.avatarUrl,
              radius: 20,
            ),
            title: Text(
              c.author.displayName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(c.content),
            trailing: Text(
              timeAgo(c.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        if (!_last)
          TextButton(
            onPressed: _loading ? null : () => _load(more: true),
            child: const Text('Ver más'),
          ),
      ],
    );
  }

  Widget _composer(Activity a) {
    if (!a.canComment) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Solo tus mutuals pueden comentar esta novedad.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.inkSoft),
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                maxLength: 300,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: _sending ? null : _send,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.peach,
                foregroundColor: AppColors.ink,
              ),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
