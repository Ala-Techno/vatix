import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/shimmer_loading.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../providers/wholesaler_products_provider.dart';
import '../widgets/wholesaler_product_card.dart';
import 'add_edit_product_screen.dart';

/// [WholesalerProductsScreen] — Wholesaler products management screen
/// Supports: real-time search, category chips, pagination (infinite scroll), and pull-to-refresh
class WholesalerProductsScreen extends StatefulWidget {
  const WholesalerProductsScreen({super.key});

  @override
  State<WholesalerProductsScreen> createState() =>
      _WholesalerProductsScreenState();
}

class _WholesalerProductsScreenState extends State<WholesalerProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WholesalerProductsProvider>().startListening(
              wholesalerId: user.id,
            );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WholesalerProductsProvider>().loadMoreProducts(
              wholesalerId: user.id,
            );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<WholesalerProductsProvider>().loadProducts(
            wholesalerId: user.id,
            refresh: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WholesalerProductsProvider>();
    final products = provider.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            AddEditProductScreen.route(context),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة صنف',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // ── Search & filter bar ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (q) => provider.setSearchQuery(q),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، الكود (SKU)، أو التصنيف...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Horizontal category chips (Categorization Chips) ─────────────
          if (provider.categories.isNotEmpty)
            Container(
              height: 44,
              color: AppColors.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(
                    label: 'جميع الأصناف',
                    isSelected: provider.selectedCategory == null,
                    onTap: () => provider.setSelectedCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ...provider.categories.map((cat) {
                    final isSelected = provider.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildCategoryChip(
                        label: cat,
                        isSelected: isSelected,
                        onTap: () => provider.setSelectedCategory(cat),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // ── Main list ─────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: _buildBody(provider, products),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    WholesalerProductsProvider provider,
    List dynamicProducts,
  ) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5,
        itemBuilder: (_, __) => const ShimmerProductCard(),
      );
    }

    if (dynamicProducts.isEmpty) {
      if (provider.searchQuery.isNotEmpty ||
          provider.selectedCategory != null) {
        return const EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'لم يتم العثور على نتائج',
          subtitle: 'لا توجد أصناف تطابق معايير البحث أو التصفية المحددة.',
        );
      }

      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد منتجات في الكتالوج بعد',
        subtitle:
            'أضف أصنافك وحدد أسعار الجملة ووحدات البيع لتظهر فوراً لتجارك المعتمدين.',
        actionLabel: 'إضافة أول صنف',
        onAction: () {
          Navigator.push(
            context,
            AddEditProductScreen.route(context),
          );
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80), // مساحة للـ FAB
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: dynamicProducts.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == dynamicProducts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return WholesalerProductCard(product: dynamicProducts[index]);
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
        width: 1,
      ),
    );
  }
}

