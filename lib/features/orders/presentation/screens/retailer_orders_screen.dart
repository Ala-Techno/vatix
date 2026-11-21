import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/error_state_widget.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/retailer_orders_provider.dart';
import 'order_details_screen.dart';

/// [RetailerOrdersScreen] — Retailer orders list screen with real-time updates
class RetailerOrdersScreen extends StatefulWidget {
  final VoidCallback? onBrowseCatalog;

  const RetailerOrdersScreen({
    super.key,
    this.onBrowseCatalog,
  });

  @override
  State<RetailerOrdersScreen> createState() => _RetailerOrdersScreenState();
}

class _RetailerOrdersScreenState extends State<RetailerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<RetailerOrdersProvider>().startListening(user.id, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetailerOrdersProvider>();

    if (provider.isLoading && !provider.hasOrders) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (provider.errorMessage != null && !provider.hasOrders) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () {
          final user = context.read<AuthProvider>().user;
          if (user != null) {
            provider.startListening(user.id, force: true);
          }
        },
      );
    }

    if (!provider.hasOrders) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد طلبات شراء حتى الآن',
        subtitle:
            'لم تقم بإرسال أي أوامر شراء بعد. تصفح كتالوج أصناف المورد المعتمد وأرسل طلبك بسهولة.',
        actionLabel: widget.onBrowseCatalog != null ? 'تصفح الكتالوج' : null,
        onAction: widget.onBrowseCatalog,
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshOrders();
      },
      child: ListView.builder(
        key: ValueKey('orders_${provider.orders.map((o) => '${o.id}_${o.status.name}').join(',')}'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: provider.orders.length,
        itemBuilder: (context, index) {
          final order = provider.orders[index];
          return KeyedSubtree(
            key: ValueKey('${order.id}_${order.status.name}'),
            child: _buildOrderCard(context, order, dateFormat),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderEntity order,
    DateFormat dateFormat,
  ) {
    final formattedDate = dateFormat.format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(initialOrder: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top row: Order short ID + date + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        order.shortId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: AppColors.primaryLight,
                        ),
                      ),
                      if (order.hasPendingWrites) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusPendingBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_queue_rounded,
                                size: 12,
                                color: AppColors.statusPending,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'بانتظار المزامنة',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.statusPending,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.status.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: order.status.color,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Order date
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // 2. Order content (wholesaler + item count)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.wholesalerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    '${order.items.length} أصناف (${order.totalItemCount} وحدة)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),

              // Quick preview of item names
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.items.take(2).map((i) => i.name).join('، ') +
                      (order.items.length > 2 ? ' ...' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textHint,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 3. Bottom row: Total + details button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي أمر الشراء',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        order.formattedTotalsSummary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'التفاصيل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
