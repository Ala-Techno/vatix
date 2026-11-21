import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/product_entity.dart';

/// [ProductsRepository] — Domain contract for wholesaler product management and retailer catalog browsing
abstract class ProductsRepository {
  // ── Wholesaler Operations ──────────────────────────────────────────────────

  /// Creates a new product in Firestore
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

  /// Updates existing product data
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

  /// Toggles product availability for orders (isAvailable)
  Future<ApiResult<Unit>> setProductAvailable({
    required String productId,
    required bool isAvailable,
  });

  /// Soft deletes a product (sets isActive to false)
  Future<ApiResult<Unit>> softDeleteProduct({
    required String productId,
  });

  /// Real-time stream of wholesaler products for instant updates
  Stream<List<ProductEntity>> watchWholesalerProducts({
    required String wholesalerId,
    bool activeOnly = true,
  });

  /// Fetches a page of wholesaler products with sorting and pagination
  /// Non-live query — triggered explicitly or via pull-to-refresh
  Future<ApiResult<ProductsPageResult>> getWholesalerProducts({
    required String wholesalerId,
    int limit = 20,
    dynamic startAfterDocument,
    bool activeOnly = true,
  });

  // ── Retailer Operations ───────────────────────────────────────────────────

  /// Fetches a page of wholesaler catalog products for authorized retailer
  /// Criteria: wholesalerId == retailer's wholesaler && isActive == true sorted by name
  Future<ApiResult<ProductsPageResult>> getRetailerProducts({
    required String wholesalerId,
    int limit = 20,
    dynamic startAfterDocument,
  });

  /// Fetches a specific product by its ID
  Future<ApiResult<ProductEntity>> getProductById({
    required String productId,
  });
}

