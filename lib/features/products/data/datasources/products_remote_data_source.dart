import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../models/product_model.dart';

/// Product page query result from DataSource
class ProductsPageData {
  final List<ProductModel> products;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const ProductsPageData({
    required this.products,
    this.lastDocument,
    required this.hasMore,
  });
}

abstract class ProductsRemoteDataSource {
  Future<ProductModel> createProduct({
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

  Future<void> updateProduct({
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

  Future<void> setProductAvailable({
    required String productId,
    required bool isAvailable,
  });

  Future<void> softDeleteProduct({
    required String productId,
  });

  Future<ProductsPageData> getWholesalerProducts({
    required String wholesalerId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    bool activeOnly = true,
  });

  /// Real-time stream of wholesaler products for instant updates without manual refresh
  Stream<List<ProductModel>> watchWholesalerProducts({
    required String wholesalerId,
    bool activeOnly = true,
  });

  Future<ProductsPageData> getRetailerProducts({
    required String wholesalerId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  });

  Future<ProductModel> getProductById({
    required String productId,
  });
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProductsRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Future<ProductModel> createProduct({
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
    final docRef = _productsRef.doc();
    final now = DateTime.now();

    final model = ProductModel(
      id: docRef.id,
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
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(model.toFirestoreMap(isCreate: true));
    return model;
  }

  @override
  Future<void> updateProduct({
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
    final updates = <String, dynamic>{
      'name': name.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'price': price,
      'currency': currency.code,
      'unit': unit.trim(),
      'category': category?.trim().isEmpty == true ? null : category?.trim(),
      'imageUrl': imageUrl,
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim().toUpperCase(),
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _productsRef.doc(productId).update(updates);
  }

  @override
  Future<void> setProductAvailable({
    required String productId,
    required bool isAvailable,
  }) async {
    await _productsRef.doc(productId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> softDeleteProduct({
    required String productId,
  }) async {
    await _productsRef.doc(productId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<ProductsPageData> getWholesalerProducts({
    required String wholesalerId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    bool activeOnly = true,
  }) async {
    Query<Map<String, dynamic>> query = _productsRef
        .where('wholesalerId', isEqualTo: wholesalerId);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    query = query.orderBy('name').limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final snapshot = await query.get();

    final products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return ProductsPageData(
      products: products,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  @override
  Stream<List<ProductModel>> watchWholesalerProducts({
    required String wholesalerId,
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _productsRef
        .where('wholesalerId', isEqualTo: wholesalerId);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('name')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<ProductsPageData> getRetailerProducts({
    required String wholesalerId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _productsRef
        .where('wholesalerId', isEqualTo: wholesalerId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final snapshot = await query.get();

    final products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return ProductsPageData(
      products: products,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  @override
  Future<ProductModel> getProductById({
    required String productId,
  }) async {
    final doc = await _productsRef.doc(productId).get();
    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'المنتج غير موجود',
      );
    }
    return ProductModel.fromFirestore(doc);
  }
}

