import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import 'product_details_bottom_sheet.dart';

/// [RetailerProductCard] — بطاقة الصنف في كتالوج التاجر
/// متكيفة من parked/product_card.dart بدون تقييمات أو مفضلة، مع دعم الوحدة، السعر المالي المنسق، والتوفر
class RetailerProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool isGrid;

  const RetailerProductCard({
    super.key,
    required this.product,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  // ── بطاقة العرض الأفقي (List View) ──────────────────────────────────────────
  Widget _buildListCard(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ProductDetailsBottomSheet.show(context, product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // مربع الصورة
                _buildProductImage(width: 58, height: 58, radius: 12),
                const SizedBox(width: 12),

                // بيانات الصنف
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 14.5,
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
                      Row(
                        children: [
                          _buildUnitBadge(product.unit),
                          if (product.category != null &&
                              product.category!.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                product.category!.trim(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          fontSize: 15,
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

                const SizedBox(width: 8),

                // شارة التوفر وأيقونة السهم
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? AppColors.statusActiveBg
                            : AppColors.statusBlockedBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.isAvailable ? 'متاح' : 'غير متوفر',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: product.isAvailable
                              ? AppColors.statusActive
                              : AppColors.statusBlocked,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── بطاقة العرض الشبكي (Grid View) ──────────────────────────────────────────
  Widget _buildGridCard(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ProductDetailsBottomSheet.show(context, product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة الصنف في رأس البطاقة
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    color: AppColors.surfaceVariant,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _buildProductImage(
                            width: double.infinity,
                            height: double.infinity,
                            radius: 0,
                          ),
                        ),
                        // شارة التوفر في الزاوية
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? AppColors.statusActive
                                  : AppColors.statusBlocked,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.isAvailable ? 'متاح' : 'معطّل',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // بيانات الصنف والسعر
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Cairo',
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          _buildUnitBadge(product.unit),
                        ],
                      ),
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage({
    required double width,
    required double height,
    required double radius,
  }) {
    if (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: product.imageUrl!,
          width: width,
          height: height,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => _buildFallbackIcon(width, height, radius),
        ),
      );
    }
    return _buildFallbackIcon(width, height, radius);
  }

  Widget _buildFallbackIcon(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: 26,
          color: product.isAvailable
              ? AppColors.primaryLight
              : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildUnitBadge(String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        unit,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

