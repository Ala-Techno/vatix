import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';

/// [BlockedScreen] — شاشة «الحساب موقوف» — Material 3
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.statusBlockedBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.statusBlocked.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 52,
                      color: AppColors.statusBlocked,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'الحساب موقوف حالياً',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.statusBlocked,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.statusBlocked.withValues(alpha: 0.2),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'تم إيقاف صلاحية وصول هذا الحساب من قِبل المورد.\nيرجى التواصل المباشر مع إدارة المورد لتسوية الحساب وإعادة تفعيله.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                ElevatedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('تسجيل الخروج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusBlocked,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
