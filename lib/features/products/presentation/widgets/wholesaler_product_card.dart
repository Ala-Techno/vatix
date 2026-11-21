import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/confirmation_dialog.dart';
import 'package:vatix/core/widgets/vatix_product_image.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/wholesaler_products_provider.dart';
import '../screens/add_edit_product_screen.dart';

/// [WholesalerProductCard] — Wholesaler product card widget in dashboard
/// Supports: quick toggle for availability, edit button, and soft delete with confirmation
class WholesalerProductCard extends StatelessWidget {
  final ProductEntity product;

  const WholesalerProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WholesalerProductsProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
          // ── Top section: Product icon/image, name, price, action menu ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon or image box
                VatixProductImage(
                  imageUrl: product.imageUrl,
                  width: 52,
                  height: 52,
                  radius: 12,
                  fit: BoxFit.cover,
                  isAvailable: product.isAvailable,
                ),
                const SizedBox(width: 12),

                // Product name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: product.isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Unit, category, and SKU badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildTag(product.unit, isAccent: false),
                          if (product.category != null &&
                              product.category!.trim().isNotEmpty)
                            _buildTag(product.category!.trim(), isAccent: false),
                          if (product.sku != null &&
                              product.sku!.trim().isNotEmpty)
                            _buildTag('SKU: ${product.sku!.trim()}',
                                isAccent: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Formatted price in smallest currency unit
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: product.isAvailable
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),

                // Popup menu button (edit / delete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 20, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        AddEditProductScreen.route(context, product: product),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.primaryLight),
                          SizedBox(width: 8),
                          Text('تعديل الصنف',
                              style: TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.statusBlocked),
                          SizedBox(width: 8),
                          Text('حذف من الكتالوج',
                              style: TextStyle(
                                  color: AppColors.statusBlocked,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Quick availability and stock bar ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                // Stock quantity (if present)
                if (product.stockQuantity != null) ...[
                  Icon(
                    Icons.layers_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'المخزون: ${product.stockQuantity} ${product.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 15,
                    color: AppColors.statusActive,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'جاهز للطلب',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
                const Spacer(),

                // Quick availability toggle (isAvailable)
                Text(
                  product.isAvailable ? 'متاح للطلب' : 'معطّل مؤقتاً',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: product.isAvailable
                        ? AppColors.statusActive
                        : AppColors.statusBlocked,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 32,
                  child: Switch(
                    value: product.isAvailable,
                    activeThumbColor: AppColors.statusActive,
                    onChanged: (val) {
                      provider.toggleAvailability(product);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {required bool isAccent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAccent
            ? AppColors.primaryLight.withValues(alpha: 0.1)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAccent
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isAccent ? FontWeight.w700 : FontWeight.w600,
          color: isAccent ? AppColors.primaryLight : AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WholesalerProductsProvider provider,
  ) async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'حذف المنتج',
      message:
          'هل أنت متأكد من حذف المنتج "${product.name}" من الكتالوج؟\nسيتم إخفاؤه فوراً عن كافة التجار، ولن يتمكن أي تاجر من طلبه.',
      confirmLabel: 'تأكيد الحذف',
      confirmColor: AppColors.statusBlocked,
      icon: Icons.delete_outline_rounded,
    );

    if (confirm == true && context.mounted) {
      final success = await provider.deleteProduct(product.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف "${product.name}" بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.statusBlocked,
          ),
        );
      }
    }
  }
}
