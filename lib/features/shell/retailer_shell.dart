import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/core/widgets/modern_bottom_nav_bar.dart';
import 'package:vatix/core/widgets/vatix_premium_app_bar.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/cart/presentation/providers/cart_provider.dart';
import 'package:vatix/features/cart/presentation/screens/cart_screen.dart';
import 'package:vatix/features/customers/presentation/providers/customers_provider.dart';
import 'package:vatix/features/customers/presentation/screens/customers_screen.dart';
import 'package:vatix/features/orders/presentation/providers/retailer_orders_provider.dart';
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
// 1. RETAILER SHELL
// ═════════════════════════════════════════════════════════════════════════════

/// [RetailerShell] — Provides necessary providers and delegates to [_RetailerShellContent]
class RetailerShell extends StatefulWidget {
  const RetailerShell({super.key});

  /// Global notifier to switch active retailer tab from any screen
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
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = RetailerShell.activeTabNotifier.value;
    RetailerShell.activeTabNotifier.addListener(_handleTabChange);
    // Start retailer orders stream upon shell load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<RetailerOrdersProvider>().startListening(user.id);
      }
    });
  }

  @override
  void dispose() {
    RetailerShell.activeTabNotifier.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted && _currentIndex != RetailerShell.activeTabNotifier.value) {
      setState(() => _currentIndex = RetailerShell.activeTabNotifier.value);
      if (_currentIndex == 2) {
        final user = context.read<AuthProvider>().user;
        if (user != null) {
          context.read<RetailerOrdersProvider>().startListening(user.id);
        }
      }
    }
  }

  Future<void> _handleBackPress() async {
    // 1. If not at first screen (index 0), navigate to first tab
    if (_currentIndex != 0) {
      RetailerShell.switchTab(0);
      return;
    }

    // 2. If already at first screen (index 0)
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app_outlined, color: Colors.white, size: 19),
                SizedBox(width: 8),
                Text(
                  'اضغط مرة أخرى لتأكيد الخروج من التطبيق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.95),
            behavior: SnackBarBehavior.floating,
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Pressed twice within 2 seconds — show premium confirmation dialog
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      _lastBackPressTime = null;
      final shouldExit = await showAppExitDialog(context);
      if (shouldExit == true) {
        await SystemNavigator.pop();
      }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: VatixPremiumAppBar(
          title: user?.businessName.isNotEmpty == true
              ? user!.businessName
              : 'منشأة التجزئة',
          subtitle: user?.ownerName.isNotEmpty == true ? user!.ownerName : null,
          roleBadge: 'تاجر',
          roleBadgeColor: AppColors.primaryLight,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout_rounded, size: 21, color: AppColors.textSecondary),
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
      try {
        context.read<RetailerOrdersProvider>().reset();
      } catch (_) {}
      context.read<AuthProvider>().logout();
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. WHOLESALER SHELL
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
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WholesalerOrdersProvider>().init(user.id);
        context.read<WholesalerProductsProvider>().startListening(
              wholesalerId: user.id,
            );
      }
    });
  }

  Future<void> _handleBackPress() async {
    // 1. If wholesaler is not at dashboard (index 0), navigate back to index 0
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // 2. If already at dashboard (index 0)
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app_outlined, color: Colors.white, size: 19),
                SizedBox(width: 8),
                Text(
                  'اضغط مرة أخرى لتأكيد الخروج من التطبيق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.95),
            behavior: SnackBarBehavior.floating,
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Pressed twice within 2 seconds — show premium confirmation dialog
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      _lastBackPressTime = null;
      final shouldExit = await showAppExitDialog(context);
      if (shouldExit == true) {
        await SystemNavigator.pop();
      }
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: VatixPremiumAppBar(
          title: user?.businessName.isNotEmpty == true
              ? user!.businessName
              : 'لوحة المورد',
          subtitle: user?.ownerName.isNotEmpty == true ? user!.ownerName : null,
          roleBadge: 'مورد',
          roleBadgeColor: AppColors.secondary,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout_rounded, size: 21, color: AppColors.textSecondary),
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
      try {
        context.read<RetailerOrdersProvider>().reset();
      } catch (_) {}
      context.read<AuthProvider>().logout();
    }
  }
}
