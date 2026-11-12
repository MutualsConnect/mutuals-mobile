import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_controller.dart';
import '../data/models/subscription_models.dart';
import '../data/subscription_repository.dart';

/// Plan actual y suscripción a Mutuals Plus.
class PlusPage extends ConsumerStatefulWidget {
  const PlusPage({super.key});

  @override
  ConsumerState<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends ConsumerState<PlusPage> {
  bool _busy = false;

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _run(
    Future<void> Function(SubscriptionRepository repo) action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(subscriptionRepositoryProvider));
      ref.invalidate(subscriptionProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) _toast(success);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la renovación?'),
        content: const Text(
          'Seguirás con los beneficios de Plus hasta que venza tu periodo actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar renovación'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _run((r) async => r.cancel(), success: 'Renovación cancelada.');
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mutuals Plus')),
      body: sub.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudo cargar tu plan',
          onRetry: () => ref.invalidate(subscriptionProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(Subscription sub) {
    final text = Theme.of(context).textTheme;
    final benefits = sub.isPlus
        ? sub.benefits.map(translateBenefit).toList()
        : plusBenefits;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        Center(
          child: Text(
            sub.isPlus ? '⭐' : '✨',
            style: const TextStyle(fontSize: 64),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub.isPlus ? 'Eres Mutuals Plus' : 'Lleva tus rachas más lejos',
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          sub.isPlus
              ? (sub.isCanceled
                    ? 'Tus beneficios terminan el ${sub.expiresAt == null ? '' : formatDate(sub.expiresAt!)}.'
                    : 'Se renueva el ${sub.expiresAt == null ? '' : formatDate(sub.expiresAt!)}.')
              : 'Plan gratis · hasta ${sub.maxActiveStreaks} rachas activas',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.peachLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sub.isPlus ? 'Tus beneficios' : 'Con Plus obtienes',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final b in benefits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅  '),
                      Expanded(child: Text(b)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!sub.isPlus) ...[
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                    (r) async => r.subscribe(BillingPeriod.monthly),
                    success: '¡Bienvenida a Plus! ⭐',
                  ),
            child: const Text('Suscribirme · Mensual'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                    (r) async => r.subscribe(BillingPeriod.yearly),
                    success: '¡Bienvenida a Plus! ⭐',
                  ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.peach, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Suscribirme · Anual'),
          ),
          const SizedBox(height: 12),
          Text(
            'Demostración: por ahora no se realiza ningún cobro.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
        ] else if (!sub.isCanceled)
          TextButton(
            onPressed: _busy ? null : _cancel,
            child: const Text('Cancelar renovación'),
          ),
      ],
    );
  }
}
