import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/interaction_repository.dart';
import '../data/models/interaction_models.dart';

/// Mi código QR, que se renueva solo antes de vencer (cada 30 s).
class MyQrPage extends ConsumerStatefulWidget {
  const MyQrPage({super.key});

  @override
  ConsumerState<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends ConsumerState<MyQrPage> {
  MyQrCode? _qr;
  String? _error;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final qr = await ref.read(interactionRepositoryProvider).myQr();
      if (!mounted) return;
      setState(() {
        _qr = qr;
        _error = null;
      });
      _startCountdown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    void tick() {
      final left = _qr!.expiresAt.difference(DateTime.now()).inSeconds;
      if (left <= 1) {
        _timer?.cancel();
        _load();
      } else {
        setState(() => _secondsLeft = left);
      }
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi código QR')),
      body: _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _qr == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.peach),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Muéstraselo a tu amigo',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: QrImageView(
                      data: _qr!.token,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_secondsLeft / 30).clamp(0.0, 1.0),
                      minHeight: 8,
                      color: AppColors.peach,
                      backgroundColor: AppColors.peachLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Se renueva en ${_secondsLeft}s',
                    style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
    );
  }
}
