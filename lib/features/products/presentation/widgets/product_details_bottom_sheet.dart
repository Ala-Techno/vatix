import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/product_entity.dart';

/// [ProductDetailsBottomSheet] — نافذة تفاصيل الصنف للتاجر
/// تعرض: الاسم، السعر بالعملة المعتمدة، وحدة البيع، كود الصنف، الوصف، والتوفر
/// وتتيح اختيار الكمية والإضافة لسلة المشتريات (Task 3.1.5)
class ProductDetailsBottomSheet extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsBottomSheet({super.key, required this.product});

  static void show(BuildContext context, ProductEntity product) {
    CartProvider? cartProvider;
    try {
      cartProvider = context.read<CartProvider>();
    } catch (_) {
      cartProvider = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (cartProvider != null) {
          return ChangeNotifierProvider.value(
            value: cartProvider,
            child: ProductDetailsBottomSheet(product: product),
          );
        }
        return ProductDetailsBottomSheet(product: product);
      },
    );
  }

  @override
  State<ProductDetailsBottomSheet> createState() =>
      _ProductDetailsBottomSheetState();
}

class _ProductDetailsBottomSheetState extends State<ProductDetailsBottomSheet> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartProvider>();
      final existingQty = cart.getQuantity(widget.product.id);
      if (existingQty > 0) {
        setState(() => _quantity = existingQty);
      }
    });
  }

  void _increment() {
    if (_quantity < 999) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    final error = cart.addItem(widget.product, quantity: _quantity);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.statusBlocked,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تمت إضافة $_quantity من «${widget.product.name}» إلى السلة',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.statusActive,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final isAlreadyInCart = cart.isInCart(product.id);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── مقبض السحب العلوي ──────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── المحتوى القابل للتمرير ──────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // صورة المنتج (إن توفرت)
                  if (product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: AppColors.surfaceVariant,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // اسم المنتج
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // شارات المنتج: الوحدة، الصنف، والـ SKU
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip(
                        icon: Icons.all_inbox_rounded,
                        label: 'الوحدة: ${product.unit}',
                        color: AppColors.primaryLight,
                      ),
                      if (product.category != null &&
                          product.category!.trim().isNotEmpty)
                        _buildChip(
                          icon: Icons.category_rounded,
                          label: product.category!.trim(),
                          color: AppColors.secondary,
                        ),
                      if (product.sku != null && product.sku!.trim().isNotEmpty)
                        _buildChip(
                          icon: Icons.tag_rounded,
                          label: 'SKU: ${product.sku!.trim()}',
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // السعر وحالة التوفر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'سعر الجملة للوحدة:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? AppColors.statusActiveBg
                              : AppColors.statusBlockedBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: product.isAvailable
                                ? AppColors.statusActive.withValues(alpha: 0.3)
                                : AppColors.statusBlocked
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.isAvailable
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 14,
                              color: product.isAvailable
                                  ? AppColors.statusActive
                                  : AppColors.statusBlocked,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.isAvailable
                                  ? 'متوفر للطلب'
                                  : 'غير متوفر حالياً',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: product.isAvailable
                                    ? AppColors.statusActive
                                    : AppColors.statusBlocked,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // وصف المنتج (إن وجد)
                  if (product.description != null &&
                      product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'الوصف والمواصفات:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description!.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // ── محدد الكمية وزر الإضافة للسلة (Task 3.1.5) ─────────────
                  if (product.isAvailable) ...[
                    Row(
                      children: [
                        const Text(
                          'الكمية المطلوبة:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Spacer(),

                        // أزرار التحكم بالكمية
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 20),
                                onPressed: _quantity > 1 ? _decrement : null,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                              Container(
                                constraints:
                                    const BoxConstraints(minWidth: 36),
                                alignment: Alignment.center,
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 20),
                                onPressed: _quantity < 999 ? _increment : null,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // زر الإضافة للسلة
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded,
                            size: 20),
                        label: Text(
                          isAlreadyInCart
                              ? 'تحديث الكمية في السلة'
                              : 'إضافة إلى السلة',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // تنبيه عدم التوفر
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusBlockedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.statusBlocked.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: AppColors.statusBlocked,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'هذا الصنف غير متوفر حالياً للطلب من قبل المورد.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.statusBlocked,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // زر الإغلاق
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
