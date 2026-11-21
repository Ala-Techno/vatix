import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/di/dependency_injection.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/core/widgets/empty_state_widget.dart';
import 'package:vatix/features/cart/presentation/providers/cart_provider.dart';
import 'package:vatix/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:vatix/features/cart/presentation/widgets/cart_summary_bar.dart';
import 'package:vatix/features/cart/presentation/widgets/cart_validation_dialog.dart';
import 'package:vatix/features/products/domain/repositories/products_repository.dart';

/// [CartScreen] — Retailer shopping cart screen.
/// Displays current cart items with total per currency and validates prices prior to proceeding.
class CartScreen extends StatelessWidget {
  final VoidCallback? onBrowseCatalog;
  final VoidCallback? onProceedToCheckout;

  const CartScreen({
    super.key,
    this.onBrowseCatalog,
    this.onProceedToCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سلة المشتريات'),
            if (cart.itemCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cart.itemCount} قطقة',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              tooltip: 'تفريغ السلة',
              color: AppColors.statusBlocked,
              onPressed: () => _confirmClearCart(context, cart),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyStateWidget(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'سلة المشتريات فارغة',
              subtitle:
                  'تصفح كتالوج أصناف المورد المعتمد وأضف الكميات المطلوبة لإنشاء أمر الشراء.',
              actionLabel: onBrowseCatalog != null ? 'تصفح الكتالوج' : null,
              onAction: onBrowseCatalog,
            )
          : Column(
              children: [
                // Cart info banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الأسعار والكميات مقفلة ومحددة مباشرة من كتالوج المورد.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemTile(
                        key: ValueKey(item.productId),
                        item: item,
                        onIncrement: () => cart.increment(item.productId),
                        onDecrement: () => cart.decrement(item.productId),
                        onRemove: () => cart.removeItem(item.productId),
                      );
                    },
                  ),
                ),

                // Summary bar and checkout action
                CartSummaryBar(
                  totalsByCurrency: cart.totalsByCurrency,
                  isLoading: cart.isValidating,
                  onCheckout: () => _handleProceed(context, cart),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context, CartProvider cart) async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'تفريغ السلة',
      message: 'هل أنت متأكد من رغبتك في حذف جميع الأصناف من السلة؟',
      confirmLabel: 'تفريغ',
      confirmColor: AppColors.statusBlocked,
    );

    if (confirm == true) {
      cart.clear();
    }
  }

  /// Re-validate prior to proceeding to checkout screen (Task 3.2)
  Future<void> _handleProceed(BuildContext context, CartProvider cart) async {
    final repository = getIt<ProductsRepository>();
    final validation = await cart.validateCart(repository);

    if (!context.mounted) return;

    if (validation.hasDiscrepancies) {
      // Show discrepancies dialog
      final accepted = await CartValidationDialog.show(
        context,
        validationResult: validation,
      );

      if (!context.mounted) return;

      if (accepted != true || cart.isEmpty) {
        return;
      }
    }

    // Proceed to order confirmation step
    if (onProceedToCheckout != null) {
      onProceedToCheckout!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم التحقق من الأسعار والتوفر بنجاح — جاهز لتأكيد الطلب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.statusActive,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
