import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// [ErrorStateWidget] — مكوّن عرض حالة الخطأ مع خيار إعادة المحاولة
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'حدث خطأ في جلب البيانات',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.statusBlockedBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.statusBlocked.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.statusBlocked,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 46),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

