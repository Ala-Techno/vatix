import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/product_entity.dart';

/// [ProductsRepository] — عقد الـ Domain لإدارة المنتجات للمورد وتصفح الكتالوج للتاجر
abstract class ProductsRepository {
  // ── عمليات المورد (Wholesaler Operations) ───────────────────────────────────

  /// إنشاء منتج جديد في Firestore
  Future<ApiResult<ProductEntity>> createProduct({
    required String wholesalerId,
    required String name,
    String? description,
    required int price,
    required Currency currency,
    required String unit,
    String? category,
    String? imageUrl,
    String? sku,
    int? stockQuantity,
    bool isAvailable = true,
  });

  /// تعديل بيانات منتج موجود
  Future<ApiResult<Unit>> updateProduct({
    required String productId,
    required String name,
    String? description,
    required int price,
    required Currency currency,
    required String unit,
    String? category,
    String? imageUrl,
    String? sku,
    int? stockQuantity,
    required bool isAvailable,
  });

  /// تغيير حالة توفر المنتج للطلب (isAvailable)
  Future<ApiResult<Unit>> setProductAvailable({
    required String productId,
    required bool isAvailable,
  });

  /// حذف ناعم للمنتج (تحويل isActive إلى false)
  Future<ApiResult<Unit>> softDeleteProduct({
    required String productId,
  });

  /// جلب صفحة منتجات المورد مع الترتيب والـ Pagination
  /// لا مستمع حيّ — يتم استدعاؤه بطلب صريح أو عند السحب للتحديث
  Future<ApiResult<ProductsPageResult>> getWholesalerProducts({
    required String wholesalerId,
    int limit = 20,
    dynamic startAfterDocument,
    bool activeOnly = true,
  });

  // ── عمليات التاجر (Retailer Operations) ────────────────────────────────────

  /// جلب صفحة منتجات كتالوج المورد للتاجر المعتمد
  /// بشرط: wholesalerId == مورد التاجر و isActive == true وترتيب بالاسم
  Future<ApiResult<ProductsPageResult>> getRetailerProducts({
    required String wholesalerId,
    int limit = 20,
    dynamic startAfterDocument,
  });

  /// جلب منتج محدد بالمعرف
  Future<ApiResult<ProductEntity>> getProductById({
    required String productId,
  });
}

