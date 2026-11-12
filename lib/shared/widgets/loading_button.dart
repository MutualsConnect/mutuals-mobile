import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Botón principal que muestra un indicador mientras `loading` es true.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: loading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.ink,
                ),
              )
            : Text(label, key: const ValueKey('label')),
      ),
    );
  }
}
