import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../data/gamification_repository.dart';
import '../data/models/gamification_models.dart';

const _layerNames = {
  AvatarLayer.base: 'Base',
  AvatarLayer.hair: 'Cabello',
  AvatarLayer.outfit: 'Ropa',
  AvatarLayer.accessory: 'Accesorios',
};

/// Tienda de ítems para personalizar tu avatar.
class AvatarPage extends ConsumerStatefulWidget {
  const AvatarPage({super.key});

  @override
  ConsumerState<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends ConsumerState<AvatarPage> {
  int? _busyId;

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _act(AvatarItem item) async {
    final repo = ref.read(gamificationRepositoryProvider);
    setState(() => _busyId = item.id);
    try {
      if (!item.owned) {
        await repo.purchaseAvatarItem(item.id);
        ref.read(authControllerProvider.notifier).refreshUser();
        _toast('¡${item.name} es tuyo! ✨');
      } else {
        await repo.equipAvatarItem(item.id);
      }
      ref.invalidate(avatarItemsProvider);
      await ref.read(avatarItemsProvider.future);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(avatarItemsProvider);
    final user = ref.watch(authControllerProvider).user;
    return DefaultTabController(
      length: AvatarLayer.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi avatar'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.ink,
            indicatorColor: AppColors.peach,
            tabs: [
              for (final l in AvatarLayer.values) Tab(text: _layerNames[l]),
            ],
          ),
        ),
        body: items.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.peach),
          ),
          error: (e, _) => ErrorState(
            message: e is ApiException
                ? e.message
                : 'No se pudo cargar la tienda',
            onRetry: () => ref.invalidate(avatarItemsProvider),
          ),
          data: (all) {
            final equipped = all.where((i) => i.equipped).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: user?.displayName ?? '',
                          url: user?.avatarUrl,
                          radius: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: equipped.isEmpty
                              ? const Text('Aún no llevas nada puesto')
                              : Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final i in equipped)
                                      Text(
                                        i.emoji,
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                  ],
                                ),
                        ),
                        Text(
                          '${user?.gems ?? 0} 💎',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final layer in AvatarLayer.values)
                        _ItemGrid(
                          items: all.where((i) => i.layer == layer).toList(),
                          busyId: _busyId,
                          onAction: _act,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.items,
    required this.busyId,
    required this.onAction,
  });

  final List<AvatarItem> items;
  final int? busyId;
  final void Function(AvatarItem) onAction;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        emoji: '🛍️',
        title: 'Nada por aquí',
        message: 'Pronto habrá más ítems.',
      );
    }
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (final item in items)
          _ItemCard(
            item: item,
            busy: busyId == item.id,
            onTap: () => onAction(item),
          ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.busy,
    required this.onTap,
  });

  final AvatarItem item;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final blocked = item.premiumOnly && !item.owned;
    final String label;
    if (item.equipped) {
      label = 'Equipado ✓';
    } else if (item.owned) {
      label = 'Equipar';
    } else if (blocked) {
      label = '⭐ Solo Plus';
    } else {
      label = item.priceGems == 0 ? 'Gratis' : 'Comprar · ${item.priceGems} 💎';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.equipped ? AppColors.peach : AppColors.peachLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      errorBuilder: (_, _, _) => Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    )
                  : Text(item.emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy || item.equipped || blocked ? null : onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.ink,
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
