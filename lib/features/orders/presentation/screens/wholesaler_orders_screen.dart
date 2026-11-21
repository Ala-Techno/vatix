import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/error_state_widget.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/wholesaler_orders_provider.dart';
import '../widgets/wholesaler_order_tile.dart';
import 'wholesaler_order_details_screen.dart';

/// [WholesalerOrdersScreen] — Wholesaler incoming orders list screen (Task 4.3)
/// Includes:
/// 1. Status filter chips (pending / approved / delivered / rejected / cancelled)
/// 2. Real-time stream for orders
/// 3. Pull-to-refresh
class WholesalerOrdersScreen extends StatefulWidget {
  const WholesalerOrdersScreen({super.key});

  @override
  State<WholesalerOrdersScreen> createState() => _WholesalerOrdersScreenState();
}

class _WholesalerOrdersScreenState extends State<WholesalerOrdersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<WholesalerOrdersProvider>().loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WholesalerOrdersProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Status filter chips (Status Chips) — Task 4.3.1
          _buildFilterChips(provider),

          // 2. Orders list or empty/error states
          Expanded(
            child: _buildOrdersContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(WholesalerOrdersProvider provider) {
    final currentStatus = provider.selectedStatus;

    final filters = [
      (label: 'المعلقة', status: OrderStatus.pending, count: provider.pendingCount),
      (label: 'المعتمدة', status: OrderStatus.approved, count: null),
      (label: 'المُسلَّمة', status: OrderStatus.delivered, count: null),
      (label: 'المرفوضة', status: OrderStatus.rejected, count: null),
      (label: 'الملغية', status: OrderStatus.cancelled, count: null),
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = currentStatus == filter.status;

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (filter.count != null && filter.count! > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.statusPendingBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filter.count}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isSelected ? Colors.white : AppColors.statusPending,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selectedColor: AppColors.primaryLight,
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primaryLight : AppColors.borderSubtle,
              ),
            ),
            onSelected: (_) => provider.setStatusFilter(filter.status),
          );
        },
      ),
    );
  }

  Widget _buildOrdersContent(WholesalerOrdersProvider provider) {
    // Error state
    if (provider.errorMessage != null && provider.ordersList.isEmpty) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.refreshOrders(),
      );
    }

    // Initial loading state
    if (provider.isLoadingOrders && provider.ordersList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Empty list state
    if (provider.ordersList.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyStateWidget(
              title: 'لا توجد طلبات واردة',
              subtitle: 'لم يتم العثور على أي أوامر شراء واردة في هذا القسم.',
              icon: Icons.inbox_rounded,
            ),
          ],
        ),
      );
    }

    // List view with pull-to-refresh
    return RefreshIndicator(
      onRefresh: provider.refreshOrders,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: provider.ordersList.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.ordersList.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final order = provider.ordersList[index];
          return WholesalerOrderTile(
            order: order,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WholesalerOrderDetailsScreen(order: order),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
