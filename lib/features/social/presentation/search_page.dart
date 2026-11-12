import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../data/social_repository.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busca por nombre o usuario',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _results()),
        ],
      ),
    );
  }

  Widget _results() {
    if (_query.length < 2) {
      return const EmptyState(
        emoji: '🔎',
        title: 'Encuentra a tus amigos',
        message: 'Escribe al menos 2 letras de su nombre o usuario.',
      );
    }
    final results = ref.watch(searchProvider(_query));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.peach)),
      error: (e, _) => ErrorState(
        message: e is ApiException ? e.message : 'No se pudo buscar',
        onRetry: () => ref.invalidate(searchProvider(_query)),
      ),
      data: (page) {
        if (page.content.isEmpty) {
          return EmptyState(emoji: '🙈', title: 'Sin resultados', message: 'Nadie coincide con "$_query".');
        }
        final text = Theme.of(context).textTheme;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: page.content.length,
          itemBuilder: (context, i) {
            final user = page.content[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: UserAvatar(name: user.displayName, url: user.avatarUrl),
              title: Text(user.displayName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              subtitle: Text('@${user.username}'),
              trailing: user.personalStreak > 0 ? Text('🔥 ${user.personalStreak}') : null,
              onTap: () => context.push('/users/${user.id}'),
            );
          },
        );
      },
    );
  }
}
