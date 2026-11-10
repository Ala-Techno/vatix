import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import '../../domain/entities/order_entity.dart';

/// [OrderApprovalBottomSheet] — نافذة منبثقة لاعتماد أمر الشراء (Task 4.4)
/// تتيح للمورد اختيار:
/// 1. آجل (دين) — يُسجَّل دين على التاجر
/// 2. نقد (كاش) — يُسجَّل دين وسداد معاً ولا يتغير الرصيد
class OrderApprovalBottomSheet extends StatefulWidget {
  final OrderEntity order;
  final Future<void> Function(PaymentType paymentType) onConfirm;

  const OrderApprovalBottomSheet({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required OrderEntity order,
    required Future<void> Function(PaymentType paymentType) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderApprovalBottomSheet(
        order: order,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<OrderApprovalBottomSheet> createState() =>
      _OrderApprovalBottomSheetState();
}

class _OrderApprovalBottomSheetState extends State<OrderApprovalBottomSheet> {
  PaymentType _selectedType = PaymentType.credit; // الافتراضي آجل (دين)
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return; // حارس الضغط المزدوج

    setState(() => _isSubmitting = true);
    try {
      final navigator = Navigator.of(context);
      await widget.onConfirm(_selectedType);
      if (mounted) {
        navigator.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusActiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.statusActive,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اعتماد أمر الشراء',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'للتاجر: ${widget.order.retailerName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ملخص إجماليات الطلب لكل عملة (Task 4.4.2)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجمالي المبالغ المستحقة للطلب:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.order.totals.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المجموع بـ ${entry.key.arabicName}:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          MoneyFormatter.format(entry.value, entry.key),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'طريقة سداد وقيد الطلب:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 10),

          // خيار 1: آجل (دين) — Task 4.4.1
          _buildPaymentOption(
            type: PaymentType.credit,
            title: 'آجل (دين)',
            subtitle: 'يُسجَّل دين على التاجر في الدفتر ويزيد رصيده المستحق.',
            icon: Icons.receipt_long_outlined,
            color: AppColors.statusBlocked,
          ),

          const SizedBox(height: 10),

          // خيار 2: نقد (كاش) — Task 4.4.1
          _buildPaymentOption(
            type: PaymentType.cash,
            title: 'نقد (كاش)',
            subtitle: 'يُسجَّل قيد دين وسداد فوري معاً، ولا يتغير رصيد التاجر.',
            icon: Icons.payments_outlined,
            color: AppColors.statusActive,
          ),

          const SizedBox(height: 24),

          // زر التأكيد مع حارس الضغط المزدوج (Task 4.4.3)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusActive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'تأكيد اعتماد الطلب (${_selectedType.label})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.borderSubtle,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
