import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/cart/domain/entities/cart_validation_result.dart';

/// [CartValidationDialog] — Dialog displaying detected discrepancies in the cart prior to order checkout.
class CartValidationDialog extends StatelessWidget {
  final CartValidationResult validationResult;

  const CartValidationDialog({
    super.key,
    required this.validationResult,
  });

  /// Displays the dialog and returns true if user agrees to proceed with new prices/updates.
  static Future<bool?> show(
    BuildContext context, {
    required CartValidationResult validationResult,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CartValidationDialog(validationResult: validationResult),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discrepancies = validationResult.discrepancies;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusPendingBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.statusPending,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'تحديثات على أصناف السلة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'قام المورد بتحديث بعض الأسعار أو حالة توفر الأصناف في الكتالوج. تم تحديث السلة تلقائياً بهذه التعديلات:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Detected discrepancies list
              ...discrepancies.map((d) => _buildDiscrepancyItem(d)),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primaryLight,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يرجى مراجعة إجمالي السلة المحدث والموافقة قبل إرسال أمر الشراء.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('العودة للسلة'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('موافق ومتابعة'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscrepancyItem(CartItemDiscrepancy d) {
    Color badgeColor;
    Color bgColor;
    IconData icon;

    switch (d.type) {
      case DiscrepancyType.unavailableOrRemoved:
        badgeColor = AppColors.statusBlocked;
        bgColor = AppColors.statusBlockedBg;
        icon = Icons.remove_circle_outline_rounded;
        break;
      case DiscrepancyType.priceChanged:
        badgeColor = AppColors.statusPending;
        bgColor = AppColors.statusPendingBg;
        icon = Icons.price_change_outlined;
        break;
      case DiscrepancyType.currencyChanged:
        badgeColor = AppColors.primaryLight;
        bgColor = AppColors.surfaceVariant;
        icon = Icons.currency_exchange_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: badgeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d.message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: badgeColor,
                fontFamily: 'Cairo',
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

