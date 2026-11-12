import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../social/data/social_repository.dart';
import '../data/interaction_repository.dart';
import '../data/models/interaction_models.dart';
import 'check_in_success.dart';

/// Interacciones que tus amigos registraron y esperan tu confirmación.
class PendingInteractionsPage extends ConsumerWidget {
  const PendingInteractionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingInteractionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Por confirmar')),
      body: pending.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudieron cargar',
          onRetry: () => ref.invalidate(pendingInteractionsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                emoji: '✅',
                title: 'Todo al día',
                message: 'Cuando un amigo registre una interacción contigo, aparecerá aquí.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _PendingCard(interaction: list[i]),
              ),
      ),
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard({required this.interaction});

  final Interaction interaction;

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;

  Future<void> _answer({required bool confirm}) async {
    final repo = ref.read(interactionRepositoryProvider);
    final id = widget.interaction.id;
    final name = widget.interaction.initiator.displayName;
    setState(() => _busy = true);
    try {
      final result = confirm ? await repo.confirm(id) : await repo.reject(id);
      ref.invalidate(pendingInteractionsProvider);
      ref.invalidate(mutualsProvider);
      if (confirm && mounted) {
        setState(() => _busy = false);
        await showCheckInSuccess(
          context,
          friendName: name,
          streakLength: result.streakLength,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final who = widget.interaction.initiator;
    final note = widget.interaction.note;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peachLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: who.displayName, url: who.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${who.displayName} dice que hablaron hoy',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('“$note”'),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _answer(confirm: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('No fue así'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _answer(confirm: true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
