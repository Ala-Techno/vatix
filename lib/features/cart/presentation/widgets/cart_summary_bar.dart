import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';

/// [CartSummaryBar] — شريط إجماليات السلة السفلي مع دعم عرض سطر مخصص لكل عملة
class CartSummaryBar extends StatelessWidget {
  final Map<Currency, int> totalsByCurrency;
  final VoidCallback? onCheckout;
  final bool isLoading;
  final String buttonLabel;

  const CartSummaryBar({
    super.key,
    required this.totalsByCurrency,
    required this.onCheckout,
    this.isLoading = false,
    this.buttonLabel = 'متابعة الطلب',
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = totalsByCurrency.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── عرض الإجماليات لكل عملة في أسطر مستقلة ──────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إجمالي السلة:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (!hasItems)
                    const Text(
                      'السلة فارغة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        fontFamily: 'Cairo',
                      ),
                    )
                  else
                    ...totalsByCurrency.entries.map((entry) {
                      final formatted =
                          MoneyFormatter.format(entry.value, entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          formatted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                            height: 1.2,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // ── زر المتابعة ────────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (hasItems && !isLoading) ? onCheckout : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48), // إلغاء الـ double.infinity الموروث من الثيم العام
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              buttonLabel,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

