import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// [ShimmerLoading] — ويدجت التحميل بتأثير البريق (Shimmer Effect) الموحد
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

/// هيكل تحميل عظمي (Skeleton Box) مرن
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// هيكل تحميل بطاقة التاجر (CustomerCard Shimmer) — متناسق مع الأبعاد الجديدة
class ShimmerCustomerCard extends StatelessWidget {
  const ShimmerCustomerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 42, height: 42, borderRadius: 12),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 6),
                      SizedBox(height: 5),
                      ShimmerBox(width: 90, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                ShimmerBox(width: 58, height: 22, borderRadius: 7),
              ],
            ),
            SizedBox(height: 10),
            Divider(height: 1),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ShimmerBox(height: 12, borderRadius: 4),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ShimmerBox(height: 12, borderRadius: 4),
                ),
              ],
            ),
            SizedBox(height: 10),
            Divider(height: 1),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(flex: 3, child: ShimmerBox(height: 38, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: ShimmerBox(height: 38, borderRadius: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// هيكل تحميل بطاقة كود الدعوة (InviteCodeCard Shimmer) — متناسق مع الأبعاد الجديدة
class ShimmerInviteCard extends StatelessWidget {
  const ShimmerInviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ShimmerBox(width: 32, height: 32, borderRadius: 9),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(height: 15, borderRadius: 6)),
                SizedBox(width: 16),
                ShimmerBox(width: 56, height: 20, borderRadius: 14),
              ],
            ),
            SizedBox(height: 14),
            ShimmerBox(height: 48, borderRadius: 12),
            SizedBox(height: 12),
            ShimmerBox(height: 42, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// هيكل تحميل بطاقة المنتج (ProductCard Shimmer)
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShimmerBox(width: 52, height: 52, borderRadius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 150, height: 14, borderRadius: 6),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      ShimmerBox(width: 60, height: 11, borderRadius: 4),
                      SizedBox(width: 8),
                      ShimmerBox(width: 50, height: 11, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 8),
                  ShimmerBox(width: 90, height: 15, borderRadius: 4),
                ],
              ),
            ),
            SizedBox(width: 10),
            ShimmerBox(width: 44, height: 26, borderRadius: 13),
          ],
        ),
      ),
    );
  }
}
