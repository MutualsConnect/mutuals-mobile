import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_header.dart';

/// Se muestra mientras se restaura la sesión guardada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandHeader(),
            SizedBox(height: 32),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.peach,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
