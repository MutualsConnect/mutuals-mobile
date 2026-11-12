import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../social/data/social_repository.dart';
import '../data/interaction_repository.dart';
import 'check_in_success.dart';

/// Escanea el QR de un amigo. Si la cámara no está disponible (por ejemplo en
/// el simulador), se puede pegar el código a mano.
class ScanQrPage extends ConsumerStatefulWidget {
  const ScanQrPage({super.key});

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  final _manual = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _submit(String token) async {
    if (_busy || token.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(interactionRepositoryProvider)
          .checkInWithQr(token.trim());
      ref.invalidate(mutualsProvider);
      if (!mounted) return;
      final other = result.initiator;
      await showCheckInSuccess(
        context,
        friendName: other.displayName,
        streakLength: result.streakLength,
      );
      if (mounted) context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: MobileScanner(
                onDetect: (capture) {
                  final value = capture.barcodes.firstOrNull?.rawValue;
                  if (value != null) _submit(value);
                },
                errorBuilder: (context, error) => Container(
                  color: AppColors.peachLight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📷', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        'No se pudo abrir la cámara.\nPuedes pegar el código abajo.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _manual,
                  decoration: const InputDecoration(
                    labelText: '¿No puedes escanear? Pega el código',
                    prefixIcon: Icon(Icons.keyboard_alt_outlined),
                  ),
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : () => _submit(_manual.text),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.ink,
                          ),
                        )
                      : const Text('Confirmar con este código'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
