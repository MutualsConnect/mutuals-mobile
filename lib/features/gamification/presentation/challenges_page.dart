import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/widgets/icon_text.dart';

import '../../../core/theme/app_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/media/photo_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../data/gamification_repository.dart';
import '../data/models/gamification_models.dart';
import '../../../core/network/api_config.dart';

/// Desafíos de esta semana con tus mutuals.
class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Desafíos')),
      body: challenges.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudieron cargar los desafíos',
          onRetry: () => ref.invalidate(challengesProvider),
        ),
        data: (list) => RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () async {
            ref.invalidate(challengesProvider);
            await ref.read(challengesProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    EmptyState(
                      icon: AppIcons.target,
                      title: 'Sin desafíos esta semana',
                      message: 'Cada lunes recibes un desafío para hacer con tus rachas activas.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ChallengeCard(challenge: list[i]),
                ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = challenge;
    final (label, color) = switch (c.status) {
      ChallengeStatus.completed => ('Completado', AppColors.glassSky),
      ChallengeStatus.expired => ('Expirado', AppColors.glass),
      ChallengeStatus.open =>
        c.submittedByMe
            ? ('Esperando a ${c.friend.displayName}', AppColors.glassSky)
            : ('Pendiente', AppColors.glass),
    };
    return Material(
      color: AppColors.glass,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/challenges/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(c.template.icon, size: 32, color: AppColors.peach),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.template.title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'con ${c.friend.displayName}',
                      style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconText(
                AppIcons.gem,
                '+${c.template.rewardGems}',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeDetailPage extends ConsumerWidget {
  const ChallengeDetailPage({super.key, required this.challengeId});

  final int challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(challengeProvider(challengeId));
    return Scaffold(
      appBar: AppBar(),
      body: challenge.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudo cargar el desafío',
          onRetry: () => ref.invalidate(challengeProvider(challengeId)),
        ),
        data: (c) => _Detail(challenge: c),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  final _content = TextEditingController();
  String? _photoPath;
  bool _busy = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await ref.read(photoPickerProvider).pick();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _submit() async {
    final c = widget.challenge;
    if (c.template.requiresPhoto && _photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este desafío necesita una foto.')),
      );
      return;
    }
    if (_content.text.trim().isEmpty && _photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo o agrega una foto.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(gamificationRepositoryProvider)
          .submitChallenge(
            c.id,
            content: _content.text.trim(),
            photoPath: _photoPath,
          );
      ref.invalidate(challengeProvider(c.id));
      ref.invalidate(challengesProvider);
      ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('¡Enviado!')));
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
    final c = widget.challenge;
    final text = Theme.of(context).textTheme;
    final canSubmit = c.status == ChallengeStatus.open && !c.submittedByMe;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Center(child: Icon(c.template.icon, size: 60, color: AppColors.peach)),
        const SizedBox(height: 8),
        Text(
          c.template.title,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          c.template.prompt,
          textAlign: TextAlign.center,
          style: text.bodyLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              UserAvatar(name: c.friend.displayName, url: c.friend.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Con ${c.friend.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconText(
                AppIcons.gem,
                '+${c.template.rewardGems}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (canSubmit) ...[
          TextField(
            controller: _content,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Cuéntalo con tus palabras…',
            ),
          ),
          const SizedBox(height: 8),
          if (_photoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(_photoPath!),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickPhoto,
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _photoPath == null
                  ? (c.template.requiresPhoto
                        ? 'Agregar foto (obligatoria)'
                        : 'Agregar foto')
                  : 'Cambiar foto',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.peach, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LoadingButton(
            label: 'Enviar mi parte',
            loading: _busy,
            onPressed: _submit,
          ),
        ] else ...[
          Text(
            'Respuestas',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (c.submissions.isEmpty) const Text('Todavía no hay respuestas.'),
          for (final s in c.submissions) _SubmissionTile(submission: s),
        ],
      ],
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.submission});

  final ChallengeSubmission submission;

  @override
  Widget build(BuildContext context) {
    final s = submission;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (!s.revealed)
            const IconText(
              AppIcons.lock,
              'Se mostrará cuando ambos cumplan el desafío.',
            )
          else ...[
            if (s.content != null && s.content!.isNotEmpty) Text(s.content!),
            if (s.photoUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  ApiConfig.mediaUrl(s.photoUrl!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const IconText(AppIcons.camera, 'Foto no disponible'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
