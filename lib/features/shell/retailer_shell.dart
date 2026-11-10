import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/core/widgets/modern_bottom_nav_bar.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/cart/presentation/providers/cart_provider.dart';
import 'package:vatix/features/cart/presentation/screens/cart_screen.dart';
import 'package:vatix/features/customers/presentation/providers/customers_provider.dart';
import 'package:vatix/features/customers/presentation/screens/customers_screen.dart';
import 'package:vatix/features/orders/presentation/providers/wholesaler_orders_provider.dart';
import 'package:vatix/features/orders/presentation/screens/checkout_screen.dart';
import 'package:vatix/features/orders/presentation/screens/retailer_orders_screen.dart';
import 'package:vatix/features/orders/presentation/screens/wholesaler_dashboard_screen.dart';
import 'package:vatix/features/orders/presentation/screens/wholesaler_orders_screen.dart';
import 'package:vatix/features/products/presentation/providers/retailer_catalog_provider.dart';
import 'package:vatix/features/products/presentation/providers/wholesaler_products_provider.dart';
import 'package:vatix/features/products/presentation/screens/retailer_catalog_screen.dart';
import 'package:vatix/features/products/presentation/screens/wholesaler_products_screen.dart';
import 'package:vatix/features/ledger/presentation/providers/retailer_account_provider.dart';
import 'package:vatix/features/ledger/presentation/screens/retailer_account_screen.dart';
import 'package:vatix/features/ledger/presentation/providers/wholesaler_ledger_provider.dart';
import 'package:vatix/features/ledger/presentation/screens/wholesaler_ledger_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// 1. RETAILER SHELL (هيكل واجهة تاجر التجزئة)
// ═════════════════════════════════════════════════════════════════════════════

/// [RetailerShell] — يوفر الـ Providers اللازمة ويفوّض لـ [_RetailerShellContent]
class RetailerShell extends StatefulWidget {
  const RetailerShell({super.key});

  /// متحكم عام لتغيير التبويب النشط لواجهة التاجر من أي شاشة
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  static void switchTab(int index) {
    activeTabNotifier.value = index;
  }

  @override
  State<RetailerShell> createState() => _RetailerShellState();
}

class _RetailerShellState extends State<RetailerShell> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RetailerCatalogProvider>(
          create: (_) => getIt<RetailerCatalogProvider>(),
        ),
        ChangeNotifierProvider<RetailerAccountProvider>(
          create: (_) => getIt<RetailerAccountProvider>(),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    _currentIndex = RetailerShell.activeTabNotifier.value;
    RetailerShell.activeTabNotifier.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    RetailerShell.activeTabNotifier.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted && _currentIndex != RetailerShell.activeTabNotifier.value) {
      setState(() => _currentIndex = RetailerShell.activeTabNotifier.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cart = context.watch<CartProvider>();

    final items = [
      const BottomNavItem(icon: Icons.grid_view_rounded, label: 'الكتالوج'),
      BottomNavItem(
        icon: Icons.shopping_cart_outlined,
        label: 'السلة',
        badgeCount: cart.itemCount,
      ),
      const BottomNavItem(icon: Icons.receipt_long_outlined, label: 'طلباتي'),
      const BottomNavItem(icon: Icons.account_balance_wallet_outlined, label: 'حسابي'),
    ];

    final screens = [
      const RetailerCatalogScreen(),
      CartScreen(
        onBrowseCatalog: () => RetailerShell.switchTab(0),
        onProceedToCheckout: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CheckoutScreen(),
            ),
          );
        },
      ),
      RetailerOrdersScreen(
        onBrowseCatalog: () => RetailerShell.switchTab(0),
      ),
      const RetailerAccountScreen(),
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
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        items: items,
        onTap: (i) => RetailerShell.switchTab(i),
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
        ChangeNotifierProvider<WholesalerOrdersProvider>(
          create: (_) => getIt<WholesalerOrdersProvider>(),
        ),
        ChangeNotifierProvider<WholesalerLedgerProvider>(
          create: (_) => getIt<WholesalerLedgerProvider>(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WholesalerOrdersProvider>().init(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final customersProvider = context.watch<CustomersProvider>();
    final ordersProvider = context.watch<WholesalerOrdersProvider>();

    final screens = [
      WholesalerDashboardScreen(
        onNavigateToOrders: () => setState(() => _currentIndex = 2),
        onNavigateToCustomers: () => setState(() => _currentIndex = 3),
      ),
      const WholesalerProductsScreen(),
      const WholesalerOrdersScreen(),
      const CustomersScreen(),
      const WholesalerLedgerScreen(),
    ];

    final items = [
      const BottomNavItem(icon: Icons.dashboard_rounded, label: 'الرئيسية'),
      const BottomNavItem(icon: Icons.inventory_2_rounded, label: 'المنتجات'),
      BottomNavItem(
        icon: Icons.list_alt_rounded,
        label: 'الطلبات',
        badgeCount: ordersProvider.pendingCount,
      ),
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
      body: IndexedStack(index: _currentIndex, children: screens),
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
