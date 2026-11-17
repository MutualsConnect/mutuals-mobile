import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/password_field.dart';
import '../data/auth_repository.dart';
import '../domain/validators.dart';

/// Crea una contraseña nueva con el código que llegó por correo.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  /// Código precargado cuando se abre desde un enlace.
  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  late final _token = TextEditingController(text: widget.token);
  final _password = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
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
      await ref
          .read(authRepositoryProvider)
          .confirmPasswordReset(
            token: _token.text,
            newPassword: _password.text,
          );
      if (mounted) setState(() => _done = true);
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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _done ? _buildDone(text) : _buildForm(text),
        ),
      ),
    );
  }

  Widget _buildDone(TextTheme text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.check_circle_outline_rounded, size: 72),
      const SizedBox(height: 24),
      Text(
        'Contraseña actualizada',
        textAlign: TextAlign.center,
        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Text(
        'Ya puedes iniciar sesión con tu nueva contraseña.',
        textAlign: TextAlign.center,
        style: text.bodyLarge,
      ),
      const SizedBox(height: 32),
      FilledButton(
        onPressed: () => context.go(Routes.login),
        child: const Text('Ir a iniciar sesión'),
      ),
    ],
  );

  Widget _buildForm(TextTheme text) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nueva contraseña',
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Pega el código del correo y elige una contraseña nueva.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          ErrorBanner(_error!),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _token,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Ingresa el código' : null,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Código del correo',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        const SizedBox(height: 14),
        PasswordField(
          controller: _password,
          label: 'Nueva contraseña',
          validator: Validators.strongPassword,
          onSubmitted: _submit,
        ),
        const SizedBox(height: 24),
        LoadingButton(
          label: 'Cambiar contraseña',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    ),
  );
}
