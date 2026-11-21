import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/shell/retailer_shell.dart';
import '../../domain/entities/order_entity.dart';

/// [OrderSuccessScreen] — Purchase order success screen
class OrderSuccessScreen extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onViewOrders;
  final VoidCallback? onBackToCatalog;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    this.onViewOrders,
    this.onBackToCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigateToOrders(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('أمر الشراء'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  children: [
                    const SizedBox(height: 12),

                    // 1. Large success icon
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.statusActiveBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.statusActive.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 54,
                          color: AppColors.statusActive,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Success title and message
                    const Center(
                      child: Text(
                        'تم إرسال أمر الشراء بنجاح!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'تم توجيه طلبك إلى "${order.wholesalerName}" وهو الآن قيد الانتظار لمراجعته واعتماده.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 3. Short order ID card with copy button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'رقم الطلب المرجعي',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.shortId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: AppColors.primaryLight,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _copyOrderId(context),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text(
                              'نسخ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              foregroundColor: AppColors.primaryLight,
                              side: const BorderSide(color: AppColors.borderSubtle),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Offline writes indicator E3
                    if (order.hasPendingWrites)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.statusPendingBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.statusPending.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.cloud_queue_rounded,
                              size: 22,
                              color: AppColors.statusPending,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مسجل محلياً (بانتظار المزامنة)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.statusPending,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'تم حفظ أمر الشراء على جهازك بنجاح، وستتم مزامنته تلقائياً مع المورد فور توفر اتصال بالشبكة.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo',
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 5. Totals summary card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'إجمالي أمر الشراء',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                '${order.items.length} أصناف (${order.totalItemCount} وحدة)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          ...order.totals.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key.arabicName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    MoneyFormatter.format(entry.value, entry.key),
                                    style: const TextStyle(
                                      fontSize: 14,
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
                  ],
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToOrders(context),
                        icon: const Icon(Icons.receipt_long_outlined, size: 20),
                        label: const Text(
                          'متابعة قائمة طلباتي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton.icon(
                        onPressed: () => _navigateToCatalog(context),
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text(
                          'العودة للكتالوج',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                            color: AppColors.textSecondary,
                          ),
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
    );
  }

  void _copyOrderId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: order.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رقم الطلب (${order.shortId}) للحافظة',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.statusActive,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToOrders(BuildContext context) {
    if (onViewOrders != null) {
      onViewOrders!();
    } else {
      // Navigate to "My Orders" tab in main shell
      RetailerShell.switchTab(2);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _navigateToCatalog(BuildContext context) {
    if (onBackToCatalog != null) {
      onBackToCatalog!();
    } else {
      // Navigate to "Catalog" tab in main shell
      RetailerShell.switchTab(0);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
