import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/customers/presentation/providers/customers_provider.dart';
import '../providers/wholesaler_orders_provider.dart';
import '../widgets/wholesaler_order_tile.dart';
import 'wholesaler_order_details_screen.dart';

/// [WholesalerDashboardScreen] — لوحة تحكم المورد B2B (Task 4.2)
/// تشتمل على:
/// 1. عداد الطلبات pending لحظياً (limit 50) ويعرض 50+ عند التجاوز (Task 4.2.1)
/// 2. عداد طلبات الانضمام المعلقة (Task 4.2.2)
/// 3. قائمة آخر 5 طلبات واردة مع اختصار للدخول للتفاصيل (Task 4.2.3)
class WholesalerDashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToCustomers;

  const WholesalerDashboardScreen({
    super.key,
    required this.onNavigateToOrders,
    required this.onNavigateToCustomers,
  });

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final customersProvider = context.watch<CustomersProvider>();
    final ordersProvider = context.watch<WholesalerOrdersProvider>();

    final pendingOrdersBadge = ordersProvider.pendingCountBadge;
    final pendingCustomersCount = customersProvider.pendingCount;

    return RefreshIndicator(
      onRefresh: () async {
        await ordersProvider.refreshOrders();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. بطاقة ترحيبية بالمنشأة
          _buildHeaderBanner(authUser?.businessName ?? 'المورد'),

          const SizedBox(height: 16),

          // 2. بطاقات المؤشرات اللحظية (KPIs)
          Row(
            children: [
              // عدّاد الطلبات المعلقة (Task 4.2.1)
              Expanded(
                child: _buildMetricCard(
                  title: 'طلبات معلّقة',
                  value: pendingOrdersBadge,
                  subtitle: 'أمر شراء بانتظار الاعتماد',
                  icon: Icons.mark_email_unread_outlined,
                  color: AppColors.statusPending,
                  onTap: onNavigateToOrders,
                ),
              ),
              const SizedBox(width: 12),
              // عدّاد طلبات الانضمام المعلقة (Task 4.2.2)
              Expanded(
                child: _buildMetricCard(
                  title: 'طلبات انضمام',
                  value: '$pendingCustomersCount',
                  subtitle: 'تجار بانتظار التفعيل',
                  icon: Icons.person_add_alt_1_outlined,
                  color: AppColors.secondary,
                  onTap: onNavigateToCustomers,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. قسم آخر 5 طلبات واردة (Task 4.2.3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 20, color: AppColors.primaryLight),
                  SizedBox(width: 8),
                  Text(
                    'آخر الطلبات الواردة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onNavigateToOrders,
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildRecentOrdersSection(context, ordersProvider),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(String businessName) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، $businessName',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'متابعة فورية للطلبات، العملاء، والعمليات التجارية',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textHint),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(
    BuildContext context,
    WholesalerOrdersProvider provider,
  ) {
    if (provider.isLoadingPending && provider.pendingOrders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final recent = provider.recentOrders;
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(
          child: Text(
            'لا توجد طلبات واردة جديدة بانتظار الاعتماد',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return Column(
      children: recent.map((order) {
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
      }).toList(),
    );
  }
}
