import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';

/// [PendingApprovalScreen] — شاشة «بانتظار موافقة المورد»
/// تستمع لحظياً للـ Stream — ستنتقل تلقائياً فور قيام المورد بتفعيل الحساب
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

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
                // أيقونة الحالة الدائرية مع إطار متناسق
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.statusPendingBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.statusPending.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 52,
                      color: AppColors.statusPending,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'طلبك قيد المراجعة',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // بطاقة بيانات التاجر والمنشأة
                if (user != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          user.businessName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'المسؤول: ${user.ownerName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const Text(
                  'تم إرسال طلب انضمامك إلى المورد بنجاح.\nسيقوم المورد بمراجعة بياناتك وتفعيل حسابك.\nستنتقل هذه الشاشة تلقائياً فور التفعيل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),

                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showAppConfirmationDialog(
                      context: context,
                      title: 'تسجيل الخروج',
                      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                      confirmLabel: 'خروج',
                      confirmColor: AppColors.statusBlocked,
                    );
                    if (confirm == true && context.mounted) {
                      context.read<AuthProvider>().logout();
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
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
