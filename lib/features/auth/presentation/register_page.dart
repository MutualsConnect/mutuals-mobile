import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/password_field.dart';
import '../application/auth_controller.dart';
import '../domain/validators.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Errores por campo devueltos por el servidor (por ejemplo, correo repetido).
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _check(String field, String? clientError) =>
      clientError ?? _serverErrors[field];

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(field));
    }
  }

  Future<void> _submit() async {
    _serverErrors = {};
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _email.text,
            username: _username.text,
            displayName: _displayName.text,
            password: _password.text,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
      _form.currentState!.validate();
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crea tu cuenta',
                      style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Empieza una racha con alguien que te importa.',
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      ErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _displayName,
                      validator: (v) => _check('displayName', Validators.displayName(v)),
                      onChanged: (_) => _clearServerError('displayName'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _username,
                      validator: (v) => _check('username', Validators.username(v)),
                      onChanged: (_) => _clearServerError('username'),
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixText: '@',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      validator: (v) => _check('email', Validators.email(v)),
                      onChanged: (_) => _clearServerError('email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _password,
                      validator: (v) => _check('password', Validators.strongPassword(v)),
                      onChanged: (_) => _clearServerError('password'),
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '8 a 72 caracteres, con mayúscula, minúscula, número y símbolo.',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(label: 'Crear cuenta', loading: _loading, onPressed: _submit),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
