import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/wrapped_models.dart';
import '../data/wrapped_repository.dart';
import 'wrapped_slides.dart';

/// Lista de tus Wrapped: el histórico y los de cada mes o año.
class WrappedPage extends ConsumerWidget {
  const WrappedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(wrappedListProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Wrapped')),
      body: list.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudo cargar tu Wrapped',
          onRetry: () => ref.invalidate(wrappedListProvider),
        ),
        data: (items) => RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () async {
            ref.invalidate(wrappedListProvider);
            await ref.read(wrappedListProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Material(
                color: AppColors.peach,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => context.push('/wrapped/all-time'),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        const Text('🎬', style: TextStyle(fontSize: 44)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todo el tiempo',
                                style: text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Tu historia completa con tus mutuals',
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_circle_fill_rounded, size: 34),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Por periodo',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const EmptyState(
                  emoji: '🗓️',
                  title: 'Tu primer Wrapped está en camino',
                  message: 'Se genera al terminar cada mes y cada año.',
                )
              else
                for (final w in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      w.periodType == WrappedPeriodType.yearly ? '🏆' : '📆',
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      w.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      w.periodType == WrappedPeriodType.yearly
                          ? 'Wrapped anual'
                          : 'Wrapped mensual',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/wrapped/story', extra: w),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapped histórico: carga los datos y abre las historias.
class AllTimeWrappedPage extends ConsumerWidget {
  const AllTimeWrappedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(allTimeWrappedProvider);
    return data.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.peach)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudo cargar tu Wrapped',
          onRetry: () => ref.invalidate(allTimeWrappedProvider),
        ),
      ),
      data: (all) => WrappedStoriesPage(
        slides: buildWrappedSlides(
          periodLabel: wrappedPeriodLabel('ALL'),
          stats: all.overall,
          allTime: all,
        ),
      ),
    );
  }
}

/// Wrapped de un periodo concreto.
class PeriodWrappedPage extends StatelessWidget {
  const PeriodWrappedPage({super.key, required this.summary});

  final WrappedSummary summary;

  @override
  Widget build(BuildContext context) => WrappedStoriesPage(
    slides: buildWrappedSlides(
      periodLabel: summary.label,
      stats: summary.stats,
    ),
  );
}

/// Pantalla completa estilo historias: toca a la derecha para avanzar y a la
/// izquierda para volver; también avanza sola cada pocos segundos.
class WrappedStoriesPage extends StatefulWidget {
  const WrappedStoriesPage({
    super.key,
    required this.slides,
    this.autoAdvance = const Duration(seconds: 6),
  });

  final List<WrappedSlide> slides;
  final Duration? autoAdvance;

  @override
  State<WrappedStoriesPage> createState() => _WrappedStoriesPageState();
}

class _WrappedStoriesPageState extends State<WrappedStoriesPage> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    final every = widget.autoAdvance;
    if (every == null || _index >= widget.slides.length - 1) return;
    _timer = Timer(every, _next);
  }

  void _go(int index) {
    if (index < 0 || index >= widget.slides.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _go(_index + 1);

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    return Scaffold(
      backgroundColor: slides[_index].color,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        color: slides[_index].color,
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _restartTimer();
                },
                itemBuilder: (_, i) => _SlideView(slide: slides[i]),
              ),
              // Zonas táctiles: izquierda = atrás, derecha = adelante.
              Positioned.fill(
                top: 90,
                bottom: 120,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _go(_index - 1),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _next,
                      ),
                    ),
                  ],
                ),
              ),
              if (slides[_index].showPlusUpsell)
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 28,
                  child: FilledButton(
                    onPressed: () => context.push('/plus'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('⭐ Ver todos con Plus'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _index
                                ? AppColors.ink
                                : AppColors.ink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final WrappedSlide slide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = slide;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 90, 28, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.scale(scale: t, child: child),
            child: Text(s.emoji, style: const TextStyle(fontSize: 96)),
          ),
          const SizedBox(height: 16),
          if (s.value != null)
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: s.value!),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Text(
                '$v',
                style: text.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 92,
                  height: 1,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            s.title,
            textAlign: TextAlign.center,
            style:
                (s.kind == SlideKind.counter
                        ? text.titleLarge
                        : text.headlineMedium)
                    ?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (s.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              s.subtitle!,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ],
          if (s.kind == SlideKind.methods) ...[
            const SizedBox(height: 24),
            _Methods(methods: s.methods),
          ],
          if (s.kind == SlideKind.friends) ...[
            const SizedBox(height: 16),
            _Friends(slide: s),
          ],
        ],
      ),
    );
  }
}

class _Methods extends StatelessWidget {
  const _Methods({required this.methods});

  final Map<String, int> methods;

  @override
  Widget build(BuildContext context) {
    final max = methods.values.fold<int>(1, (m, v) => v > m ? v : m);
    return Column(
      children: [
        for (final e in methods.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    methodLabel(e.key),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: e.value / max),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 14,
                        color: AppColors.ink,
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Friends extends StatelessWidget {
  const _Friends({required this.slide});

  final WrappedSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in slide.friends.take(5))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f.friend.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${f.interactions} 💬 · mejor 🔥 ${f.bestStreak}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
