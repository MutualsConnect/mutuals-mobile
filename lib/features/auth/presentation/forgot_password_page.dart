import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_button.dart';
import '../data/auth_repository.dart';
import '../domain/validators.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _sent ? _buildSent(text) : _buildForm(text),
          ),
        ),
      ),
    );
  }

  Widget _buildSent(TextTheme text) => Column(
        key: const ValueKey('sent'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 42),
          ),
          const SizedBox(height: 24),
          Text(
            'Revisa tu correo',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Si ${_email.text.trim()} está registrado, te enviamos las instrucciones para restablecer tu contraseña.',
            textAlign: TextAlign.center,
            style: text.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: () => context.pop(), child: const Text('Volver al inicio de sesión')),
        ],
      );

  Widget _buildForm(TextTheme text) => Form(
        key: _form,
        child: Column(
          key: const ValueKey('form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recupera tu contraseña',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresa tu correo y te enviaremos un enlace para crear una nueva.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(label: 'Enviar enlace', loading: _loading, onPressed: _submit),
          ],
        ),
      );
}
