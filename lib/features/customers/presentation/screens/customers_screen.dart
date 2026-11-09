import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/invite_code_card.dart';

/// [CustomersScreen] — شاشة إدارة العملاء (التجار) وأكواد الدعوة للمورد
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

    // ربط المستمعين اللحظيين بهوية المورد الحالي
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
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
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('طلبات الانضمام'),
                          if (provider.pendingCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${provider.pendingCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      text: provider.activeCount > 0
                          ? 'المفعّلون (${provider.activeCount})'
                          : 'المفعّلون',
                    ),
                    Tab(
                      text: provider.blockedCount > 0
                          ? 'الموقوفون (${provider.blockedCount})'
                          : 'الموقوفون',
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
              customers: provider.pendingCustomers,
              emptyIcon: Icons.hourglass_empty_rounded,
              emptyTitle: 'لا توجد طلبات انضمام جديدة',
              emptySubtitle:
                  'عندما يسجل تاجر جديد بكود الدعوة الخاص بك، سيظهر طلبه هنا للمراجعة والموافقة.',
            ),
            _buildCustomerList(
              customers: provider.activeCustomers,
              emptyIcon: Icons.people_outline_rounded,
              emptyTitle: 'لا يوجد تجار مفعّلون حالياً',
              emptySubtitle:
                  'شارك كود الدعوة مع تجارك واعتمد طلباتهم ليتمكنوا من طلب منتجاتك.',
            ),
            _buildCustomerList(
              customers: provider.blockedCustomers,
              emptyIcon: Icons.block_flipped,
              emptyTitle: 'لا يوجد تجار موقوفون',
              emptySubtitle: 'قائمة التجار الذين قمت بإيقاف حساباتهم ستظهر هنا.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList({
    required List<CustomerEntity> customers,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarHeaderDelegate oldDelegate) {
    return false;
  }
}

