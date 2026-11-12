import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../social/data/models/social_models.dart';
import '../../social/data/social_repository.dart';
import '../data/models/streak_models.dart';
import '../data/streak_repository.dart';

/// Invitaciones de racha recibidas y enviadas.
class InvitationsPage extends StatelessWidget {
  const InvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invitaciones'),
          bottom: const TabBar(
            labelColor: AppColors.ink,
            indicatorColor: AppColors.peach,
            tabs: [
              Tab(text: 'Recibidas'),
              Tab(text: 'Enviadas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InvitationList(received: true),
            _InvitationList(received: false),
          ],
        ),
      ),
    );
  }
}

class _InvitationList extends ConsumerWidget {
  const _InvitationList({required this.received});

  final bool received;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = received
        ? receivedInvitationsProvider
        : sentInvitationsProvider;
    final invitations = ref.watch(provider);
    return invitations.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.peach),
      ),
      error: (e, _) => ErrorState(
        message: e is ApiException
            ? e.message
            : 'No se pudieron cargar las invitaciones',
        onRetry: () => ref.invalidate(provider),
      ),
      data: (list) => RefreshIndicator(
        color: AppColors.ink,
        onRefresh: () async {
          ref.invalidate(provider);
          await ref.read(provider.future);
        },
        child: list.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  EmptyState(
                    emoji: received ? '📭' : '📤',
                    title: received
                        ? 'Sin invitaciones'
                        : 'No has enviado invitaciones',
                    message: received
                        ? 'Cuando un mutual te invite a una racha, aparecerá aquí.'
                        : 'Invita a un mutual desde la pestaña Mutuals.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _InvitationCard(invitation: list[i], received: received),
              ),
      ),
    );
  }
}

class _InvitationCard extends ConsumerStatefulWidget {
  const _InvitationCard({required this.invitation, required this.received});

  final StreakInvitation invitation;
  final bool received;

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function(StreakRepository repo) action, {
    String? success,
  }) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(streakRepositoryProvider));
      ref.invalidate(receivedInvitationsProvider);
      ref.invalidate(sentInvitationsProvider);
      ref.invalidate(mutualsProvider);
      if (success != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
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
    final UserSummary other = widget.received
        ? widget.invitation.inviter
        : widget.invitation.invitee;
    final id = widget.invitation.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peachLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(name: other.displayName, url: other.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other.displayName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.received
                          ? 'Quiere empezar una racha contigo'
                          : 'Esperando su respuesta',
                      style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.received)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run((r) => r.respond(id, accept: false)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.ink),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (r) => r.respond(id, accept: true),
                            success: '¡Racha iniciada! 🔥',
                          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run((r) => r.cancelInvitation(id)),
                child: const Text('Cancelar invitación'),
              ),
            ),
        ],
      ),
    );
  }
}
