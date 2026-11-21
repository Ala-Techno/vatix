import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../providers/retailer_orders_provider.dart';

/// [OrderDetailsScreen] — Purchase order details screen with real-time tracking
class OrderDetailsScreen extends StatefulWidget {
  final OrderEntity initialOrder;

  const OrderDetailsScreen({
    super.key,
    required this.initialOrder,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Stream<OrderEntity?> _orderStream;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    final repo = getIt<OrdersRepository>();
    _orderStream = repo.watchOrder(orderId: widget.initialOrder.id);
    _orderStream.listen((updatedOrder) {
      if (updatedOrder != null && mounted) {
        context.read<RetailerOrdersProvider>().updateOrderLocally(updatedOrder);
      }
    });
  }

  Future<void> _handleCancelOrder(OrderEntity order) async {
    if (_isCanceling) return;

    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'إلغاء أمر الشراء',
      message: 'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ لا يمكن التراجع عن هذه الخطوة.',
      confirmLabel: 'تأكيد الإلغاء',
      confirmColor: AppColors.statusBlocked,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCanceling = true);

    final authUser = context.read<AuthProvider>().user;
    final retailerId = authUser?.id ?? order.retailerId;
    final ordersProvider = context.read<RetailerOrdersProvider>();

    final result = await ordersProvider.cancelOrder(
      orderId: order.id,
      retailerId: retailerId,
    );

    if (!mounted) return;
    setState(() => _isCanceling = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إلغاء أمر الشراء بنجاح.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.statusActive,
          ),
        );
      case ApiFailure(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.statusBlocked,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderEntity?>(
      stream: _orderStream,
      initialData: widget.initialOrder,
      builder: (context, snapshot) {
        final order = snapshot.data ?? widget.initialOrder;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('طلب ${order.shortId}'),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Order header and status card
                    _buildHeaderCard(order),

                    const SizedBox(height: 16),

                    // 2. Rejection state if applicable
                    if (order.status == OrderStatus.rejected) ...[
                      _buildRejectionCard(order),
                      const SizedBox(height: 16),
                    ],

                    // 3. Offline writes indicator
                    if (order.hasPendingWrites) ...[
                      _buildPendingWritesCard(),
                      const SizedBox(height: 16),
                    ],

                    // 4. Wholesaler card
                    _buildWholesalerCard(order),

                    const SizedBox(height: 16),

                    // 5. Items list
                    _buildItemsCard(order),

                    const SizedBox(height: 16),

                    // 6. Notes if present
                    if (order.note != null && order.note!.trim().isNotEmpty) ...[
                      _buildNotesCard(order.note!),
                      const SizedBox(height: 16),
                    ],

                    // 7. Totals
                    _buildTotalsCard(order),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Cancel button bar if order is pending
              if (order.canCancel) _buildCancelOrderBottomBar(order),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(OrderEntity order) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');
    final formattedDate = dateFormat.format(order.createdAt);

    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رقم أمر الشراء',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.shortId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.status.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: order.status.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: order.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: order.status.color,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'تاريخ الطلب: $formattedDate',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          if (order.paymentType != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 15,
                  color: AppColors.statusActive,
                ),
                const SizedBox(width: 6),
                Text(
                  'طريقة السداد المعتمدة: ${order.paymentType!.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusActive,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionCard(OrderEntity order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusBlockedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.statusBlocked.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            size: 22,
            color: AppColors.statusBlocked,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'سبب رفض الطلب',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusBlocked,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.rejectionReason?.isNotEmpty == true
                      ? order.rejectionReason!
                      : 'لم يحدد المورد سبباً للرفض.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingWritesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusPending.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.cloud_queue_rounded,
            size: 20,
            color: AppColors.statusPending,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'الطلب مسجل محلياً وبانتظار المزامنة مع الخادم فور توفر الاتصال.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholesalerCard(OrderEntity order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المورد المعتمد',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  order.wholesalerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderEntity order) {
    return Container(
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
                'الأصناف والأسعار المعتمدة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                '${order.items.length} أصناف',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.quantity} ${item.unit} × ${item.formattedUnitPrice}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedLineTotal,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'ملاحظات أمر الشراء',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(OrderEntity order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الإجماليات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...order.totals.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي بـ ${entry.key.arabicName}:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
    );
  }

  Widget _buildCancelOrderBottomBar(OrderEntity order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _isCanceling ? null : () => _handleCancelOrder(order),
          icon: _isCanceling
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.statusBlocked,
                  ),
                )
              : const Icon(Icons.cancel_outlined, size: 20),
          label: Text(
            _isCanceling ? 'جارِ إلغاء الطلب...' : 'إلغاء أمر الشراء',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.statusBlocked,
            side: const BorderSide(color: AppColors.statusBlocked),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
