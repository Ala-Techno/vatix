import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';

/// [CartItemTile] — بطاقة عرض بند السلة الذكية والحديثة
/// مصممة بنظام طبقتين لمنع أي تجاوز أبعاد (Zero Overflows)
/// وتتيح إنقاص الكمية حتى 0 ليختفي الصنف تلقائياً بدون زر حذف منفصل
class CartItemTile extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. الجزء العلوي: الصورة + تفاصيل المنتج والوحدة ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الصنف
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: AppColors.surfaceVariant,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 26,
                              color: AppColors.textHint,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 26,
                            color: AppColors.textHint,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // اسم الصنف وشارة الوحدة والـ SKU
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'الوحدة: ${item.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (item.sku != null && item.sku!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SKU: ${item.sku!.trim()}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textHint,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),

            // ── 2. الجزء السفلي: الأسعار + وحدة التحكم الذكية بالكمية ────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // الأسعار (سعر الوحدة والإجمالي الإجمالي)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'سعر الوحدة: ${item.formattedUnitPrice}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'الإجمالي: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Flexible(
                            child: Text(
                              item.formattedLineTotal,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // وحدة التحكم الذكية بالأرقام (+ / -)
                // عند الكمية 1 تظهر أيقونة السلة الحمراء، وبالنقر ينقص ويختفي تلقائياً
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الإنقاص (يتحول لأيقونة الحذف عند 1 للحذف المباشر)
                      InkWell(
                        onTap: onDecrement,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(
                            item.quantity == 1
                                ? Icons.delete_outline_rounded
                                : Icons.remove_rounded,
                            size: 18,
                            color: item.quantity == 1
                                ? AppColors.statusBlocked
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // عرض الكمية الحالية
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),

                      // زر الزيادة
                      InkWell(
                        onTap: item.quantity < 999 ? onIncrement : null,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: item.quantity < 999
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
