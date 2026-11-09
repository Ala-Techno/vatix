import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/core/widgets/modern_bottom_nav_bar.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/customers/presentation/providers/customers_provider.dart';
import 'package:vatix/features/customers/presentation/screens/customers_screen.dart';
import 'package:vatix/features/products/presentation/providers/retailer_catalog_provider.dart';
import 'package:vatix/features/products/presentation/providers/wholesaler_products_provider.dart';
import 'package:vatix/features/products/presentation/screens/retailer_catalog_screen.dart';
import 'package:vatix/features/products/presentation/screens/wholesaler_products_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// 1. RETAILER SHELL (هيكل واجهة تاجر التجزئة)
// ═════════════════════════════════════════════════════════════════════════════

/// [RetailerShell] — يوفر الـ Providers اللازمة ويفوّض لـ [_RetailerShellContent]
class RetailerShell extends StatelessWidget {
  const RetailerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RetailerCatalogProvider>(
      create: (_) => getIt<RetailerCatalogProvider>(),
      child: const _RetailerShellContent(),
    );
  }
}

class _RetailerShellContent extends StatefulWidget {
  const _RetailerShellContent();

  @override
  State<_RetailerShellContent> createState() => _RetailerShellContentState();
}

class _RetailerShellContentState extends State<_RetailerShellContent> {
  int _currentIndex = 0;

  static const _items = [
    BottomNavItem(icon: Icons.grid_view_rounded, label: 'الكتالوج'),
    BottomNavItem(icon: Icons.shopping_cart_outlined, label: 'السلة'),
    BottomNavItem(icon: Icons.receipt_long_outlined, label: 'طلباتي'),
    BottomNavItem(icon: Icons.account_balance_wallet_outlined, label: 'حسابي'),
  ];

  static const _screens = [
    RetailerCatalogScreen(),
    _RetailerCartScreen(),
    _RetailerOrdersScreen(),
    _RetailerAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.businessName.isNotEmpty == true
                      ? user!.businessName
                      : 'منشأة التجزئة',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'تاجر',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            if (user?.ownerName.isNotEmpty == true)
              Text(
                user!.ownerName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟',
      confirmLabel: 'خروج',
      confirmColor: AppColors.statusBlocked,
    );
    if (confirm == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. WHOLESALER SHELL (هيكل واجهة المورد)
// ═════════════════════════════════════════════════════════════════════════════

class WholesalerShell extends StatelessWidget {
  const WholesalerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CustomersProvider>(
          create: (_) => getIt<CustomersProvider>(),
        ),
        ChangeNotifierProvider<WholesalerProductsProvider>(
          create: (_) => getIt<WholesalerProductsProvider>(),
        ),
      ],
      child: const _WholesalerShellContent(),
    );
  }
}

class _WholesalerShellContent extends StatefulWidget {
  const _WholesalerShellContent();

  @override
  State<_WholesalerShellContent> createState() => _WholesalerShellContentState();
}

class _WholesalerShellContentState extends State<_WholesalerShellContent> {
  int _currentIndex = 0;

  static const _screens = [
    _WholesalerDashboardScreen(),
    WholesalerProductsScreen(),
    _WholesalerOrdersScreen(),
    CustomersScreen(),
    _WholesalerLedgerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final customersProvider = context.watch<CustomersProvider>();

    final items = [
      const BottomNavItem(icon: Icons.dashboard_rounded, label: 'الرئيسية'),
      const BottomNavItem(icon: Icons.inventory_2_rounded, label: 'المنتجات'),
      const BottomNavItem(icon: Icons.list_alt_rounded, label: 'الطلبات'),
      BottomNavItem(
        icon: Icons.people_outline_rounded,
        label: 'العملاء',
        badgeCount: customersProvider.pendingCount,
      ),
      const BottomNavItem(icon: Icons.book_rounded, label: 'الدفتر'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.businessName.isNotEmpty == true
                      ? user!.businessName
                      : 'لوحة المورد',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'مورد',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            if (user?.ownerName.isNotEmpty == true)
              Text(
                user!.ownerName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        items: items,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب المورد؟',
      confirmLabel: 'خروج',
      confirmColor: AppColors.statusBlocked,
    );
    if (confirm == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. RETAILER SUB-SCREENS (شاشات تاجر التجزئة — الموقتة)
// ═════════════════════════════════════════════════════════════════════════════

/// شاشة سلة التاجر
class _RetailerCartScreen extends StatelessWidget {
  const _RetailerCartScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleBanner(
          title: 'سلة الطلبات الحالية',
          subtitle:
              'راجع الكميات والأسعار قبل إرسال أمر الشراء إلى المورد لاعتماده.',
          icon: Icons.shopping_cart_outlined,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 16),
        _buildCartItem(
          name: 'حليب مكثف محلى ممتاز 390 جم',
          unitPriceSubunits: 18500,
          currency: Currency.yer,
          quantity: 2,
        ),
        _buildCartItem(
          name: 'زيت دوار الشمس صافي 1.5 لتر',
          unitPriceSubunits: 5200,
          currency: Currency.sar,
          quantity: 5,
        ),
        const SizedBox(height: 20),

        // بطاقة الإجمالي وأمر الشراء
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ملخص الطلب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الأصناف (YER):',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    MoneyFormatter.format(37000, Currency.yer),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الأصناف (SAR):',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    MoneyFormatter.format(26000, Currency.sar),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Divider(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال أمر الشراء إلى المورد بنجاح'),
                        backgroundColor: AppColors.statusActive,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('إرسال أمر الشراء للمورد'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem({
    required String name,
    required int unitPriceSubunits,
    required Currency currency,
    required int quantity,
  }) {
    final total = unitPriceSubunits * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.statusBlocked),
                tooltip: 'حذف من السلة',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سعر الوحدة: ${MoneyFormatter.format(unitPriceSubunits, currency)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'الإجمالي: ${MoneyFormatter.format(total, currency)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شاشة طلبات التاجر
class _RetailerOrdersScreen extends StatelessWidget {
  const _RetailerOrdersScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleBanner(
          title: 'سجل الطلبات الواردة والمرسلة',
          subtitle: 'تتبع حالة أوامر الشراء المرسلة للمورد والفواتير المعتمدة.',
          icon: Icons.receipt_long_outlined,
          color: AppColors.statusPending,
        ),
        const SizedBox(height: 16),
        _buildOrderCard(
          orderNumber: 'ORD-2026-0041',
          date: 'اليوم، 10:30 ص',
          status: 'قيد المراجعة',
          statusColor: AppColors.statusPending,
          totalSubunits: 37000,
          currency: Currency.yer,
          itemsCount: 4,
        ),
        _buildOrderCard(
          orderNumber: 'ORD-2026-0038',
          date: 'أمس، 04:15 م',
          status: 'معتمد وجار التجهيز',
          statusColor: AppColors.statusActive,
          totalSubunits: 26000,
          currency: Currency.sar,
          itemsCount: 2,
        ),
      ],
    );
  }

  Widget _buildOrderCard({
    required String orderNumber,
    required String date,
    required String status,
    required Color statusColor,
    required int totalSubunits,
    required Currency currency,
    required int itemsCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تاريخ الطلب: $date • عدد الأصناف: $itemsCount',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي القيمة:'),
              Text(
                MoneyFormatter.format(totalSubunits, currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شاشة حساب التاجر وديونه
class _RetailerAccountScreen extends StatelessWidget {
  const _RetailerAccountScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleBanner(
          title: 'الدفتر المالي والحساب',
          subtitle:
              'كشف حساب تفصيلي يوضح المسحوبات، السندات، والأرصدة المستحقة.',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الرصيد القائم المستحق للمورد',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                MoneyFormatter.format(124500, Currency.yer),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'بالإضافة إلى: ${MoneyFormatter.format(15000, Currency.sar)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. WHOLESALER SUB-SCREENS (شاشات المورد المصممة باحترافية)
// ═════════════════════════════════════════════════════════════════════════════

/// شاشة لوحة تحكم المورد
class _WholesalerDashboardScreen extends StatelessWidget {
  const _WholesalerDashboardScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleBanner(
          title: 'لوحة القيادة والمؤشرات B2B',
          subtitle:
              'متابعة فورية للمبيعات، طلبات التجار الجديدة، والأرصدة المعلقة.',
          icon: Icons.analytics_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),

        // بطاقات المؤشرات الرقمية (KPIs)
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي المبيعات (YER)',
                value: MoneyFormatter.format(842000, Currency.yer),
                icon: Icons.trending_up_rounded,
                color: AppColors.statusActive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'المبيعات (SAR)',
                value: MoneyFormatter.format(124000, Currency.sar),
                icon: Icons.payments_outlined,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'طلبات جديدة',
                value: '3 طلبات',
                icon: Icons.mark_email_unread_outlined,
                color: AppColors.statusPending,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'الديون القائمة',
                value: MoneyFormatter.format(310000, Currency.yer),
                icon: Icons.receipt_long_outlined,
                color: AppColors.statusBlocked,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


/// شاشة الطلبات الواردة للمورد
class _WholesalerOrdersScreen extends StatelessWidget {
  const _WholesalerOrdersScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleBanner(
          title: 'الطلبات الواردة من التجار',
          subtitle:
              'مراجعة أوامر الشراء، اعتماد الكميات، وتأكيد التجهيز والتسليم.',
          icon: Icons.list_alt_rounded,
          color: AppColors.statusPending,
        ),
      ],
    );
  }
}

/// شاشة دفتر الديون للمورد
class _WholesalerLedgerScreen extends StatelessWidget {
  const _WholesalerLedgerScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleBanner(
          title: 'دفتر الحسابات والذمم المدينة',
          subtitle:
              'سجل القيود المزدوجة، الذمم المالية على التجار، وسندات القبض.',
          icon: Icons.book_outlined,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. SHARED HELPERS
// ═════════════════════════════════════════════════════════════════════════════

Widget _buildModuleBanner({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderSubtle),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
