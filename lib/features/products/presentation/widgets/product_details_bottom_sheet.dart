import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';

/// [ProductDetailsBottomSheet] — نافذة تفاصيل الصنف للتاجر
/// تعرض: الاسم، السعر بالعملة المعتمدة، وحدة البيع، كود الصنف، الوصف، والتوفر
/// ملاحظة: زر «إضافة للسلة» مخفي حتى المرحلة M3 حسب الخطة الرسمية
class ProductDetailsBottomSheet extends StatelessWidget {
  final ProductEntity product;

  const ProductDetailsBottomSheet({super.key, required this.product});

  static void show(BuildContext context, ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailsBottomSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
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
                  // صورة المنتج أو الأيقونة الافتراضية
                  if (product.imageUrl != null &&
                      product.imageUrl!.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: AppColors.surfaceVariant,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 48,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          size: 38,
                          color: AppColors.primaryLight,
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
                      // شارة التوفر
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? AppColors.statusActiveBg
                              : AppColors.statusBlockedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: product.isAvailable
                                ? AppColors.statusActive.withValues(alpha: 0.3)
                                : AppColors.statusBlocked.withValues(alpha: 0.3),
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

                  // تنبيه المرحلة M3 بخصوص زر الإضافة للسلة (حسب متطلبات الخطة §2.6.4)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'إضافة الأصناف إلى السلة وإرسال أوامر الشراء ستُتاح في المرحلة القادمة (M3).',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // زر الإغلاق
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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

