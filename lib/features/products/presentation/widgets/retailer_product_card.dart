import 'package:flutter/material.dart';
import 'package:vatix/core/theme/app_colors.dart';
import 'package:vatix/core/widgets/vatix_product_image.dart';
import '../../domain/entities/product_entity.dart';
import 'product_details_bottom_sheet.dart';

/// [RetailerProductCard] — Retailer catalog product card widget
/// Adapted for unit support, formatted financial price, and availability status
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

  // ── Horizontal list card (List View) ─────────────────────────────────────────
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
                // Image box
                _buildProductImage(width: 58, height: 58, radius: 12),
                const SizedBox(width: 12),

                // Product details
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

                // Availability badge and arrow icon
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

  // ── Grid card (Grid View) ─────────────────────────────────────────────────
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
              // Product image on top of card
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
                        // Corner availability and stock badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (product.isAvailable && (product.stockQuantity == null || product.stockQuantity! > 0))
                                  ? AppColors.statusActive
                                  : AppColors.statusBlocked,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (product.isAvailable && (product.stockQuantity == null || product.stockQuantity! > 0))
                                  ? (product.stockQuantity != null ? 'متاح (${product.stockQuantity})' : 'متاح')
                                  : (product.stockQuantity != null && product.stockQuantity! <= 0 ? 'نفذ' : 'معطّل'),
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

              // Product details and price
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
    return VatixProductImage(
      imageUrl: product.imageUrl,
      width: width,
      height: height,
      radius: radius,
      fit: BoxFit.cover,
      isAvailable: product.isAvailable,
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

