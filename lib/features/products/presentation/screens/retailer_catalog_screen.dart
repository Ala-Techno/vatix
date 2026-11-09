import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/core/widgets/error_state_widget.dart';
import 'package:vatix/core/widgets/shimmer_loading.dart';
import 'package:vatix/features/auth/presentation/providers/auth_provider.dart';
import '../providers/retailer_catalog_provider.dart';
import '../widgets/retailer_product_card.dart';

/// [RetailerCatalogScreen] — شاشة كتالوج الأصناف لتاجر التجزئة
/// تدعم: البحث المحلي، شرائح التصنيفات، التبديل بين الشبكة والقائمة، السحب للتحديث، والـ Pagination
class RetailerCatalogScreen extends StatefulWidget {
  const RetailerCatalogScreen({super.key});

  @override
  State<RetailerCatalogScreen> createState() => _RetailerCatalogScreenState();
}

class _RetailerCatalogScreenState extends State<RetailerCatalogScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wholesalerId = context.read<AuthProvider>().user?.wholesalerId;
      if (wholesalerId != null && wholesalerId.isNotEmpty) {
        context.read<RetailerCatalogProvider>().loadCatalog(
              wholesalerId: wholesalerId,
            );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final wholesalerId = context.read<AuthProvider>().user?.wholesalerId;
      if (wholesalerId != null && wholesalerId.isNotEmpty) {
        context.read<RetailerCatalogProvider>().loadMoreCatalog(
              wholesalerId: wholesalerId,
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
    final wholesalerId = context.read<AuthProvider>().user?.wholesalerId;
    if (wholesalerId != null && wholesalerId.isNotEmpty) {
      await context.read<RetailerCatalogProvider>().loadCatalog(
            wholesalerId: wholesalerId,
            refresh: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetailerCatalogProvider>();
    final products = provider.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── شريط البحث والتصفية وزر تبديل العرض ─────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (q) => provider.setSearchQuery(q),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، الكود (SKU)...',
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
                const SizedBox(width: 8),
                // زر التبديل بين القائمة والشبكة
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: IconButton(
                    icon: Icon(
                      provider.isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    tooltip: provider.isGridView ? 'عرض كقائمة' : 'عرض كشبكة',
                    onPressed: () => provider.toggleViewMode(),
                  ),
                ),
              ],
            ),
          ),

          // ── شرائح التصنيفات الأفقية (Categories) ────────────────────
          if (provider.categories.isNotEmpty)
            Container(
              height: 44,
              color: AppColors.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(
                    label: 'الكل',
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

          // ── المحتوى الرئيسي ─────────────────────────────────────────
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
    RetailerCatalogProvider provider,
    List dynamicProducts,
  ) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5,
        itemBuilder: (_, __) => const ShimmerProductCard(),
      );
    }

    if (provider.errorMessage != null && provider.products.isEmpty) {
      return ErrorStateWidget(
        title: 'تعذّر تحميل الكتالوج',
        message: provider.errorMessage!,
        onRetry: _handleRefresh,
      );
    }

    if (dynamicProducts.isEmpty) {
      if (provider.searchQuery.isNotEmpty ||
          provider.selectedCategory != null) {
        return const EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'لم يتم العثور على أصناف',
          subtitle: 'لا توجد أصناف مطابقة لكلمات البحث أو التصنيف المحدد.',
        );
      }

      return const EmptyStateWidget(
        icon: Icons.storefront_outlined,
        title: 'كتالوج المورد فارغ حالياً',
        subtitle:
            'لم يقم المورد بإضافة أصناف مفعّلة للكتالوج بعد. يرجى مراجعة المورد أو تحديث الشاشة بالسحب.',
      );
    }

    // عرض الشبكة (Grid View)
    if (provider.isGridView) {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(14),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.76,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: dynamicProducts.length + (provider.isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= dynamicProducts.length) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return RetailerProductCard(
            product: dynamicProducts[index],
            isGrid: true,
          );
        },
      );
    }

    // عرض القائمة (List View)
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        return RetailerProductCard(
          product: dynamicProducts[index],
          isGrid: false,
        );
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
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.borderSubtle,
      ),
    );
  }
}

