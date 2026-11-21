import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/shimmer_loading.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/invite_code_card.dart';

/// [CustomersScreen] — Customers (retailers) and invite codes management screen for wholesalers.
/// Designed with comfortable spacing without RenderFlex overflow.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CustomersProvider>().init(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            const SliverToBoxAdapter(
              child: InviteCodeCard(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeaderDelegate(
                TabBar(
                  controller: _tabController,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    _buildTab(
                      label: 'الطلبات',
                      count: provider.pendingCount,
                      countColor: AppColors.statusPending,
                    ),
                    _buildTab(
                      label: 'المفعّلون',
                      count: provider.activeCount,
                      countColor: AppColors.statusActive,
                    ),
                    _buildTab(
                      label: 'الموقوفون',
                      count: provider.blockedCount,
                      countColor: AppColors.statusBlocked,
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCustomerList(
              isLoading: provider.isLoadingCustomers,
              customers: provider.pendingCustomers,
              emptyIcon: Icons.hourglass_empty_rounded,
              emptyTitle: 'لا توجد طلبات انضمام جديدة',
              emptySubtitle:
                  'عندما يسجل تاجر جديد باستخدام كود الدعوة الخاص بك، سيظهر طلبه هنا لتراجعه وتعتمده فوراً.',
              iconColor: AppColors.statusPending,
            ),
            _buildCustomerList(
              isLoading: provider.isLoadingCustomers,
              customers: provider.activeCustomers,
              emptyIcon: Icons.people_outline_rounded,
              emptyTitle: 'لا يوجد تجار مفعّلون حالياً',
              emptySubtitle:
                  'شارك كود الدعوة أعلاه مع تجارك، وبمجرد قبول طلباتهم سيتمكنون من مشاهدة الكتالوج وإرسال الطلبات.',
              iconColor: AppColors.statusActive,
            ),
            _buildCustomerList(
              isLoading: provider.isLoadingCustomers,
              customers: provider.blockedCustomers,
              emptyIcon: Icons.block_flipped,
              emptyTitle: 'لا يوجد تجار موقوفون',
              emptySubtitle:
                  'التجار الذين تقرر إيقاف حساباتهم أو تعليق التعامل معهم سيظهرون في هذه القائمة.',
              iconColor: AppColors.statusBlocked,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required int count,
    required Color countColor,
  }) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: countColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList({
    required bool isLoading,
    required List<CustomerEntity> customers,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    Color? iconColor,
  }) {
    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => const ShimmerCustomerCard(),
      );
    }

    if (customers.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        iconColor: iconColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        return CustomerCard(customer: customers[index]);
      },
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarHeaderDelegate(this._tabBar);

  @override
  double get minExtent => 52.0;

  @override
  double get maxExtent => 52.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: overlapsContent
            ? const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(child: _tabBar),
    );
  }

  @override
  bool shouldRebuild(_TabBarHeaderDelegate oldDelegate) {
    return false;
  }
}
