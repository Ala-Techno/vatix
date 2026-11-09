import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/widgets/modern_bottom_nav_bar.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import 'package:vatix/features/customers/presentation/providers/customers_provider.dart';
import 'package:vatix/features/customers/presentation/screens/customers_screen.dart';

/// Shell التاجر — 4 تبويبات (الكتالوج، السلة، طلباتي، حسابي)
class RetailerShell extends StatefulWidget {
  const RetailerShell({super.key});

  @override
  State<RetailerShell> createState() => _RetailerShellState();
}

class _RetailerShellState extends State<RetailerShell> {
  int _currentIndex = 0;

  static const _items = [
    BottomNavItem(icon: Icons.grid_view_rounded, label: 'الكتالوج'),
    BottomNavItem(icon: Icons.shopping_cart_outlined, label: 'السلة'),
    BottomNavItem(icon: Icons.receipt_long_outlined, label: 'طلباتي'),
    BottomNavItem(icon: Icons.account_balance_wallet_outlined, label: 'حسابي'),
  ];

  static final _screens = [
    _Placeholder(label: 'الكتالوج', icon: Icons.grid_view_rounded),
    _Placeholder(label: 'السلة', icon: Icons.shopping_cart_outlined),
    _Placeholder(label: 'طلباتي', icon: Icons.receipt_long_outlined),
    _Placeholder(label: 'حسابي وديوني', icon: Icons.account_balance_wallet_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.businessName.isNotEmpty == true
                  ? user!.businessName
                  : 'Vatix — تاجر',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (user?.ownerName.isNotEmpty == true)
              Text(
                user!.ownerName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Shell المورد — 5 تبويبات (الرئيسية، المنتجات، الطلبات، العملاء، الدفتر)
class WholesalerShell extends StatelessWidget {
  const WholesalerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomersProvider>(
      create: (_) => getIt<CustomersProvider>(),
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

  static final _screens = [
    const _Placeholder(label: 'لوحة التحكم', icon: Icons.dashboard_outlined),
    const _Placeholder(label: 'إدارة المنتجات', icon: Icons.inventory_2_outlined),
    const _Placeholder(label: 'الطلبات الواردة', icon: Icons.list_alt_outlined),
    const CustomersScreen(),
    const _Placeholder(label: 'دفتر الديون', icon: Icons.book_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final customersProvider = context.watch<CustomersProvider>();

    final items = [
      const BottomNavItem(icon: Icons.dashboard_outlined, label: 'الرئيسية'),
      const BottomNavItem(icon: Icons.inventory_2_outlined, label: 'المنتجات'),
      const BottomNavItem(icon: Icons.list_alt_outlined, label: 'الطلبات'),
      BottomNavItem(
        icon: Icons.people_outline,
        label: 'العملاء',
        badgeCount: customersProvider.pendingCount,
      ),
      const BottomNavItem(icon: Icons.book_outlined, label: 'الدفتر'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.businessName.isNotEmpty == true
                  ? '${user!.businessName} (مورد)'
                  : 'Vatix — لوحة المورد',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (user?.ownerName.isNotEmpty == true)
              Text(
                user!.ownerName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Widget نائب لكل تبويب لحين بناء الشاشة الحقيقية
class _Placeholder extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Placeholder({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(label,
              style:
                  TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('قيد الإنشاء في المرحلة القادمة',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
