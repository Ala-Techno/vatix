import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customers_provider.dart';

/// [CustomerCard] — بطاقة عرض بيانات التاجر والإجراءات وفق إرشادات Material 3
/// معالجة هندسية دقيقة للمساحات لمنع أي RenderFlex Overflow مهما كانت دقة الشاشة
class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── رأس البطاقة: الأيقونة، الاسم، الشارة ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.businessName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'المسؤول: ${customer.ownerName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(customer: customer),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── بيانات الاتصال والمدينة (توزيع مساحة مرن ومحمي) ───────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // جهة الهاتف مع زر النسخ السريع
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _copyPhone(context, customer.phone),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              customer.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // جهة المدينة
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customer.city,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── أزرار الإجراءات مع حماية تامة من التجاوز ──────────────
          if (customer.isPending || customer.isActive || customer.isBlocked) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _buildActionButtons(context, provider),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    CustomersProvider provider,
  ) {
    if (customer.isPending) {
      return Row(
        children: [
          // زر القبول
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: provider.isActionLoading
                    ? null
                    : () async {
                        final success =
                            await provider.acceptCustomer(customer.id);
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تفعيل حساب "${customer.businessName}" بنجاح',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: AppColors.statusActive,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusActive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'قبول وتفعيل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // زر الرفض
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: provider.isActionLoading
                    ? null
                    : () => _handleBlockOrReject(context, provider, isReject: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusBlocked,
                  side: const BorderSide(color: AppColors.statusBlocked, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'رفض',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (customer.isActive) {
      return SizedBox(
        height: 40,
        child: OutlinedButton(
          onPressed: provider.isActionLoading
              ? null
              : () => _handleBlockOrReject(context, provider, isReject: false),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.statusBlocked, width: 1.2),
            foregroundColor: AppColors.statusBlocked,
            minimumSize: const Size(double.infinity, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block_rounded, size: 15, color: AppColors.statusBlocked),
                SizedBox(width: 6),
                Text(
                  'إيقاف / حظر التاجر',
                  style: TextStyle(
                    color: AppColors.statusBlocked,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (customer.isBlocked) {
      return SizedBox(
        height: 40,
        child: OutlinedButton(
          onPressed: provider.isActionLoading
              ? null
              : () async {
                  final success =
                      await provider.unblockCustomer(customer.id);
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إلغاء حظر وإعادة تفعيل "${customer.businessName}"',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppColors.statusActive,
                      ),
                    );
                  }
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.statusActive,
            side: const BorderSide(color: AppColors.statusActive, width: 1.2),
            minimumSize: const Size(double.infinity, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 16),
                SizedBox(width: 6),
                Text(
                  'إلغاء الحظر وإعادة التفعيل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('تم نسخ رقم الهاتف: $phone'),
          ],
        ),
        backgroundColor: AppColors.primaryLight,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleBlockOrReject(
    BuildContext context,
    CustomersProvider provider, {
    required bool isReject,
  }) async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: isReject ? 'رفض طلب الانضمام' : 'حظر التاجر',
      message: isReject
          ? 'هل أنت متأكد من رفض طلب انضمام منشأة "${customer.businessName}"؟ سيتم تحويل حالته إلى موقوف.'
          : 'هل أنت متأكد من إيقاف منشأة "${customer.businessName}"؟ لن يتمكن من تصفح منتجاتك أو إرسال طلبات جديدة.',
      confirmLabel: isReject ? 'تأكيد الرفض' : 'تأكيد الإيقاف',
      confirmColor: AppColors.statusBlocked,
      icon: isReject ? Icons.cancel_outlined : Icons.block_rounded,
    );

    if (confirm == true && context.mounted) {
      final success = await provider.blockCustomer(customer.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isReject
                  ? 'تم رفض طلب "${customer.businessName}"'
                  : 'تم إيقاف حساب "${customer.businessName}"',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.statusBlocked,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    if (customer.isPending) return AppColors.statusPending;
    if (customer.isActive) return AppColors.statusActive;
    return AppColors.statusBlocked;
  }
}

/// [StatusBadge] — شارة حالة التاجر وفق ألوان النظام
class _StatusBadge extends StatelessWidget {
  final CustomerEntity customer;

  const _StatusBadge({required this.customer});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final Color bgColor;
    final IconData icon;

    if (customer.isPending) {
      label = 'بانتظار الموافقة';
      color = AppColors.statusPending;
      bgColor = AppColors.statusPendingBg;
      icon = Icons.schedule_rounded;
    } else if (customer.isActive) {
      label = 'مفعّل';
      color = AppColors.statusActive;
      bgColor = AppColors.statusActiveBg;
      icon = Icons.check_circle_rounded;
    } else {
      label = 'موقوف';
      color = AppColors.statusBlocked;
      bgColor = AppColors.statusBlockedBg;
      icon = Icons.block_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
