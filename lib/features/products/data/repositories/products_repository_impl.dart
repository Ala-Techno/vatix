import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_data_source.dart';

/// [ProductsRepositoryImpl] — تطبيق مستودع المنتجات
class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remoteDataSource;

  ProductsRepositoryImpl({
    required ProductsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
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
  }) async {
    try {
      final model = await _remoteDataSource.createProduct(
        wholesalerId: wholesalerId,
        name: name,
        description: description,
        price: price,
        currency: currency,
        unit: unit,
        category: category,
        imageUrl: imageUrl,
        sku: sku,
        stockQuantity: stockQuantity,
        isAvailable: isAvailable,
      );
      return Success(model);
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر إضافة المنتج: $e'));
    }
  }

  @override
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
  }) async {
    try {
      await _remoteDataSource.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        currency: currency,
        unit: unit,
        category: category,
        imageUrl: imageUrl,
        sku: sku,
        stockQuantity: stockQuantity,
        isAvailable: isAvailable,
      );
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر تعديل بيانات المنتج: $e'));
    }
  }

  @override
  Future<ApiResult<Unit>> setProductAvailable({
    required String productId,
    required bool isAvailable,
  }) async {
    try {
      await _remoteDataSource.setProductAvailable(
        productId: productId,
        isAvailable: isAvailable,
      );
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر تحديث حالة التوفر: $e'));
    }
  }

  @override
  Future<ApiResult<Unit>> softDeleteProduct({
    required String productId,
  }) async {
    try {
      await _remoteDataSource.softDeleteProduct(productId: productId);
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر حذف المنتج: $e'));
    }
  }

  @override
  Future<ApiResult<ProductsPageResult>> getWholesalerProducts({
    required String wholesalerId,
    int limit = 20,
    dynamic startAfterDocument,
    bool activeOnly = true,
  }) async {
    try {
      final pageData = await _remoteDataSource.getWholesalerProducts(
        wholesalerId: wholesalerId,
        limit: limit,
        startAfterDocument:
            startAfterDocument as DocumentSnapshot<Map<String, dynamic>>?,
        activeOnly: activeOnly,
      );

      return Success(
        ProductsPageResult(
          products: pageData.products,
          lastDocument: pageData.lastDocument,
          hasMore: pageData.hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر جلب قائمة المنتجات: $e'));
    }
  }

  @override
  Future<ApiResult<ProductsPageResult>> getRetailerProducts({
    required String wholesalerId,
    int limit = 20,
    dynamic startAfterDocument,
  }) async {
    try {
      final pageData = await _remoteDataSource.getRetailerProducts(
        wholesalerId: wholesalerId,
        limit: limit,
        startAfterDocument:
            startAfterDocument as DocumentSnapshot<Map<String, dynamic>>?,
      );

      return Success(
        ProductsPageResult(
          products: pageData.products,
          lastDocument: pageData.lastDocument,
          hasMore: pageData.hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر تحميل كتالوج المنتجات: $e'));
    }
  }

  @override
  Future<ApiResult<ProductEntity>> getProductById({
    required String productId,
  }) async {
    try {
      final model = await _remoteDataSource.getProductById(productId: productId);
      return Success(model);
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر جلب بيانات المنتج: $e'));
    }
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية لإجراء هذه العملية على المنتجات.';
      case 'not-found':
        return 'المنتج المطلوب غير موجود أو تم حذفه.';
      case 'unavailable':
        return 'تعذّر الاتصال بخادم قاعدة البيانات، تحقق من الإنترنت.';
      default:
        return e.message ?? 'حدث خطأ في قاعدة البيانات (${e.code})';
    }
  }
}
