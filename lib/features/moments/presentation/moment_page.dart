import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/media/photo_picker.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/motion/animated_count.dart';
import '../../../shared/motion/confetti.dart';
import '../../../shared/motion/flip_reveal.dart';
import '../../../shared/motion/haptics.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../social/data/models/social_models.dart';
import '../../social/data/social_repository.dart';
import '../../streaks/data/streak_repository.dart';
import '../data/models/moment_models.dart';
import '../data/moment_repository.dart';
import 'countdown_ring.dart';

/// El momento de foto: cuenta regresiva, cámara, espera y revelación de las dos fotos.
class MomentPage extends ConsumerStatefulWidget {
  const MomentPage({super.key, required this.momentId});

  final int momentId;

  @override
  ConsumerState<MomentPage> createState() => _MomentPageState();
}

class _MomentPageState extends ConsumerState<MomentPage> {
  final _caption = TextEditingController();
  Timer? _tick;
  String? _photoPath;
  bool _cameraUnavailable = false;
  bool _submitting = false;
  bool _celebrated = false;
  String? _error;

  /// Cada segundo se redibuja la cuenta regresiva.
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ref.read(photoPickerProvider);
    try {
      final path = await picker.takePhoto();
      if (path != null && mounted) setState(() => _photoPath = path);
    } catch (_) {
      // Sin cámara (por ejemplo en el simulador): ofrecemos la galería.
      if (!mounted) return;
      setState(() => _cameraUnavailable = true);
      final path = await picker.pick();
      if (path != null && mounted) setState(() => _photoPath = path);
    }
  }

  Future<void> _submit() async {
    final path = _photoPath;
    if (path == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(momentRepositoryProvider)
          .submitPhoto(widget.momentId, path, caption: _caption.text);
      Haptics.medium();
      ref.invalidate(momentProvider(widget.momentId));
      ref.invalidate(activeMomentsProvider);
    } on ApiException catch (e) {
      // Si se acabó el tiempo, la pantalla pasa sola a "se acabó el tiempo".
      ref.invalidate(momentProvider(widget.momentId));
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Cuando el momento se completa: vibración fuerte y se actualiza el resto de la app.
  void _onCompleted() {
    if (_celebrated) return;
    _celebrated = true;
    Haptics.success();
    ref.invalidate(mutualsProvider);
    ref.invalidate(activeMomentsProvider);
    ref.invalidate(momentHistoryProvider);
    ref.read(authControllerProvider.notifier).refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final moment = ref.watch(momentProvider(widget.momentId));
    ref.listen(momentProvider(widget.momentId), (previous, next) {
      if (next.value?.isCompleted == true) _onCompleted();
    });
    final value = moment.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Momento'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
          onPressed: () => context.pop(),
        ),
      ),
      body: value != null
          ? _content(value)
          : moment.hasError
          ? ErrorState(
              message: moment.error is ApiException
                  ? (moment.error! as ApiException).message
                  : 'No se pudo cargar el momento',
              onRetry: () => ref.invalidate(momentProvider(widget.momentId)),
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.peach),
            ),
    );
  }

  Widget _content(Moment m) {
    if (m.isCompleted) return _RevealView(moment: m);
    if (m.status == MomentStatus.expired) return _ExpiredView(moment: m);
    final remaining = m.remainingSeconds();
    // Si el reloj llegó a cero, pedimos el estado real al servidor.
    if (remaining == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(momentProvider(widget.momentId));
      });
    }
    final total = m.expiresAt.difference(m.startedAt).inSeconds;
    return m.submittedByMe
        ? _WaitingView(
            moment: m,
            remaining: remaining,
            total: total,
            localPhoto: _photoPath,
          )
        : _CaptureView(
            moment: m,
            remaining: remaining,
            total: total,
            photoPath: _photoPath,
            caption: _caption,
            cameraUnavailable: _cameraUnavailable,
            submitting: _submitting,
            error: _error,
            onTake: _takePhoto,
            onRetake: () => setState(() => _photoPath = null),
            onSubmit: _submit,
          );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.moment,
    required this.remaining,
    required this.total,
    required this.photoPath,
    required this.caption,
    required this.cameraUnavailable,
    required this.submitting,
    required this.error,
    required this.onTake,
    required this.onRetake,
    required this.onSubmit,
  });

  final Moment moment;
  final int remaining;
  final int total;
  final String? photoPath;
  final TextEditingController caption;
  final bool cameraUnavailable;
  final bool submitting;
  final String? error;
  final VoidCallback onTake;
  final VoidCallback onRetake;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final friend = moment.friend;
    final hasPhoto = photoPath != null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              Center(
                child: CountdownRing(
                  remaining: remaining,
                  total: total,
                  size: hasPhoto ? 140 : 220,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                moment.startedByMe
                    ? '¡Sube tu foto!'
                    : '¡${friend.displayName} lanzó un momento!',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Toma una foto de lo que estás haciendo ahora mismo. Cuando las dos fotos lleguen a tiempo, la racha se confirma sola.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              _FriendStatus(friend: friend, submitted: moment.friendSubmitted),
              const SizedBox(height: 16),
              if (error != null) ...[
                ErrorBanner(error!),
                const SizedBox(height: 12),
              ],
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.file(
                      File(photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.peachLight,
                        child: Center(
                          child: Text('📸', style: TextStyle(fontSize: 64)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caption,
                  maxLength: 140,
                  decoration: const InputDecoration(
                    hintText: '¿Qué están haciendo? (opcional)',
                  ),
                ),
              ] else if (cameraUnavailable)
                Text(
                  'No pudimos abrir la cámara. Elige una foto de tu galería.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                ),
            ],
          ),
        ),
        // Botones fijos abajo: con el reloj corriendo no hay que desplazarse para enviar.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: hasPhoto
                ? Row(
                    children: [
                      TextButton(
                        onPressed: submitting ? null : onRetake,
                        child: const Text('Tomar otra'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LoadingButton(
                          label: 'Enviar foto',
                          loading: submitting,
                          onPressed: onSubmit,
                        ),
                      ),
                    ],
                  )
                : FilledButton.icon(
                    onPressed: onTake,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Tomar foto'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FriendStatus extends StatelessWidget {
  const _FriendStatus({required this.friend, required this.submitted});

  final UserSummary friend;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: submitted ? AppColors.sky : AppColors.peachLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: friend.displayName,
            url: friend.avatarUrl,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              submitted
                  ? '${friend.displayName} ya subió su foto ✓'
                  : 'Esperando la foto de ${friend.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.moment,
    required this.remaining,
    required this.total,
    required this.localPhoto,
  });

  final Moment moment;
  final int remaining;
  final int total;
  final String? localPhoto;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mine = moment.myPhoto;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Center(
          child: CountdownRing(remaining: remaining, total: total, size: 180),
        ),
        const SizedBox(height: 12),
        Text(
          '¡Tu foto ya salió!',
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Esperando a ${moment.friend.displayName}. Cuando suba la suya, se revelan las dos y la racha se confirma.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        if (mine != null || localPhoto != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: _MomentImage(url: mine?.photoUrl, localPath: localPhoto),
            ),
          ),
      ],
    );
  }
}

class _ExpiredView extends StatelessWidget {
  const _ExpiredView({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏰', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(
              'Se acabó el tiempo',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'No llegaron las dos fotos a tiempo. Puedes lanzar otro momento cuando quieras o confirmar la racha de otra forma.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las dos fotos reveladas, con confeti y los días de racha.
class _RevealView extends ConsumerWidget {
  const _RevealView({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final streak = ref.watch(streakDetailProvider(moment.streakId)).value;
    final mine = moment.myPhoto;
    final theirs = moment.friendPhoto;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              '¡Momento completado!',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (streak != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 22)),
                  AnimatedCount(
                    value: streak.currentLength,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    streak.currentLength == 1
                        ? ' día de racha'
                        : ' días de racha',
                    style: text.titleMedium,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PhotoCard(photo: mine, label: 'Tú'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PhotoCard(
                    photo: theirs,
                    label: moment.friend.displayName,
                    delay: const Duration(milliseconds: 350),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('¡Genial!'),
            ),
          ],
        ),
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.label,
    this.delay = Duration.zero,
  });

  final MomentPhoto? photo;
  final String label;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final caption = photo?.caption;
    return FlipReveal(
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: _MomentImage(url: photo?.photoUrl),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (caption != null && caption.isNotEmpty)
            Text(caption, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Foto de un momento: del archivo local si todavía lo tenemos, y si no, de la red.
class _MomentImage extends StatelessWidget {
  const _MomentImage({this.url, this.localPath});

  final String? url;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.peachLight,
      child: Center(child: Text('📷', style: TextStyle(fontSize: 48))),
    );
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _network(placeholder),
      );
    }
    return _network(placeholder);
  }

  Widget _network(Widget placeholder) {
    final u = url;
    if (u == null) return placeholder;
    return Image.network(
      ApiConfig.mediaUrl(u),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
