import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../social/data/models/social_models.dart';
import '../../social/data/social_repository.dart';
import '../data/economy_repository.dart';
import '../data/models/economy_models.dart';

/// Billetera: saldo, compra de escudos, regalos e historial.
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _history = <WalletTransaction>[];
  int _page = 0;
  bool _last = true;
  bool _historyLoading = true;
  bool _busy = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _loadHistory({bool more = false}) async {
    setState(() => _historyLoading = true);
    try {
      final page = await ref
          .read(economyRepositoryProvider)
          .transactions(page: more ? _page + 1 : 0);
      if (!mounted) return;
      setState(() {
        if (!more) _history.clear();
        _history.addAll(page.content);
        _page = page.page;
        _last = page.last;
      });
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _afterChange() async {
    ref.invalidate(walletProvider);
    ref.read(authControllerProvider.notifier).refreshUser();
    await _loadHistory();
  }

  Future<void> _buy(Wallet wallet) async {
    setState(() => _busy = true);
    try {
      await ref.read(economyRepositoryProvider).purchaseShields(_quantity);
      if (!mounted) return;
      _toast(
        _quantity == 1
            ? '¡Escudo comprado! 🛡️'
            : '¡$_quantity escudos comprados! 🛡️',
      );
      setState(() => _quantity = 1);
      await _afterChange();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gift() async {
    final friend = await showModalBottomSheet<UserSummary>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _FriendPicker(),
    );
    if (friend == null || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Regalar un escudo a ${friend.displayName}?'),
        content: const Text('Se descontará un escudo de tu billetera.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regalar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(economyRepositoryProvider).giftShield(friend.id);
      if (!mounted) return;
      _toast('Le regalaste un escudo a ${friend.displayName} 🎁');
      await _afterChange();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Billetera')),
      body: wallet.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudo cargar tu billetera',
          onRetry: () => ref.invalidate(walletProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(Wallet wallet) {
    final text = Theme.of(context).textTheme;
    final cost = _quantity * wallet.shieldPriceGems;
    final canBuy = cost <= wallet.gems;
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () async {
        ref.invalidate(walletProvider);
        await _loadHistory();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Row(
            children: [
              _Balance(emoji: '💎', value: wallet.gems, label: 'Gemas'),
              const SizedBox(width: 12),
              _Balance(emoji: '🛡️', value: wallet.shields, label: 'Escudos'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Comprar escudos',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Cada escudo cuesta ${wallet.shieldPriceGems} 💎 y protege una racha un día.',
            style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.peachLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cantidad',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Menos',
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Más',
                          onPressed: _quantity < 5
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy || !canBuy ? null : () => _buy(wallet),
                  child: Text('Comprar por $cost 💎'),
                ),
                if (!canBuy)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Te faltan ${cost - wallet.gems} 💎. Gana gemas completando semanas de racha.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy || wallet.shields < 1 ? null : _gift,
            icon: const Icon(Icons.card_giftcard_rounded),
            label: const Text('Regalar un escudo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.peach, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Movimientos',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty && !_historyLoading)
            const EmptyState(
              emoji: '🧾',
              title: 'Sin movimientos',
              message: 'Tus compras, regalos y ganancias aparecerán aquí.',
            )
          else
            for (final t in _history) _TransactionTile(transaction: t),
          if (_historyLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.peach),
              ),
            )
          else if (!_last)
            TextButton(
              onPressed: () => _loadHistory(more: true),
              child: const Text('Ver más'),
            ),
        ],
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.sky,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final positive = t.amount > 0;
    final who = t.counterpartyUsername;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(t.currencyEmoji, style: const TextStyle(fontSize: 26)),
      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        [if (who != null) '@$who', timeAgo(t.createdAt)].join(' · '),
      ),
      trailing: Text(
        '${positive ? '+' : ''}${t.amount}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: positive ? const Color(0xFF2E7D4F) : AppColors.danger,
        ),
      ),
    );
  }
}

/// Lista de mutuals para elegir a quién regalar un escudo.
class _FriendPicker extends ConsumerWidget {
  const _FriendPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutuals = ref.watch(mutualsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿A quién se lo regalas?',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            mutuals.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.peach),
                ),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No se pudieron cargar tus mutuals.'),
              ),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aún no tienes mutuals a quienes regalar.'),
                    )
                  : Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final m in list)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(
                                name: m.friend.displayName,
                                url: m.friend.avatarUrl,
                              ),
                              title: Text(
                                m.friend.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text('@${m.friend.username}'),
                              onTap: () => Navigator.pop(context, m.friend),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
