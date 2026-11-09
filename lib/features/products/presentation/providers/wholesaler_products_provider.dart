import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';

/// [WholesalerProductsProvider] — إدارة حالة منتجات المورد
/// يدعم: التحميل بالصفحات (Pagination)، البحث المحلي، التصفية بالتصنيفات، والعمليات الفورية
class WholesalerProductsProvider extends ChangeNotifier {
  final ProductsRepository _repository;

  WholesalerProductsProvider({required ProductsRepository repository})
      : _repository = repository;

  List<ProductEntity> _products = [];
  dynamic _lastDocument;
  bool _hasMore = true;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedCategory;

  // Getters
  List<ProductEntity> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  /// استخراج التصنيفات الفريدة من المنتجات المحملة
  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      if (p.category != null && p.category!.trim().isNotEmpty) {
        set.add(p.category!.trim());
      }
    }
    return set.toList();
  }

  /// تصفية المنتجات محلياً بالاسم والـ SKU والتصنيف
  List<ProductEntity> get filteredProducts {
    return _products.where((p) {
      // 1. تصفية التصنيف
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (p.category?.trim() != _selectedCategory!.trim()) {
          return false;
        }
      }

      // 2. تصفية نص البحث
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final nameMatch = p.name.toLowerCase().contains(query);
        final skuMatch = p.sku?.toLowerCase().contains(query) ?? false;
        final categoryMatch = p.category?.toLowerCase().contains(query) ?? false;
        return nameMatch || skuMatch || categoryMatch;
      }

      return true;
    }).toList();
  }

  /// تحميل أول صفحة أو تحديث القائمة بالسحب (Pull to refresh)
  Future<void> loadProducts({
    required String wholesalerId,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _lastDocument = null;
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getWholesalerProducts(
      wholesalerId: wholesalerId,
      limit: 20,
      startAfterDocument: null,
      activeOnly: true,
    );

    _isLoading = false;

    if (result is Success<ProductsPageResult>) {
      _products = List.from(result.data.products);
      _lastDocument = result.data.lastDocument;
      _hasMore = result.data.hasMore;
    } else if (result is ApiFailure<ProductsPageResult>) {
      _errorMessage = result.failure.message;
    }

    notifyListeners();
  }

  /// تحميل الصفحة التالية عند التمرير لأسفل (Infinite Scroll)
  Future<void> loadMoreProducts({required String wholesalerId}) async {
    if (_isLoadingMore || !_hasMore || _isLoading || _lastDocument == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final result = await _repository.getWholesalerProducts(
      wholesalerId: wholesalerId,
      limit: 20,
      startAfterDocument: _lastDocument,
      activeOnly: true,
    );

    _isLoadingMore = false;

    if (result is Success<ProductsPageResult>) {
      _products.addAll(result.data.products);
      _lastDocument = result.data.lastDocument;
      _hasMore = result.data.hasMore;
    } else if (result is ApiFailure<ProductsPageResult>) {
      _errorMessage = result.failure.message;
    }

    notifyListeners();
  }

  /// إضافة منتج جديد
  Future<bool> createProduct({
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
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createProduct(
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

    _isSaving = false;

    if (result is Success<ProductEntity>) {
      // إدراج المنتج في بداية القائمة مباشرة
      _products.insert(0, result.data);
      notifyListeners();
      return true;
    } else if (result is ApiFailure<ProductEntity>) {
      _errorMessage = result.failure.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return false;
  }

  /// تعديل بيانات منتج
  Future<bool> updateProduct({
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
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateProduct(
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

    _isSaving = false;

    if (result is Success) {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
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
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } else if (result is ApiFailure) {
      _errorMessage = (result as ApiFailure).failure.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return false;
  }

  /// تبديل حالة توفر المنتج للطلب (مفتاح سريع)
  Future<bool> toggleAvailability(ProductEntity product) async {
    final newStatus = !product.isAvailable;

    // تحديث تفاؤلي سريع في الواجهة
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product.copyWith(isAvailable: newStatus);
      notifyListeners();
    }

    final result = await _repository.setProductAvailable(
      productId: product.id,
      isAvailable: newStatus,
    );

    if (result is ApiFailure) {
      // التراجع عن التحديث التفاؤلي عند الفشل
      if (index != -1) {
        _products[index] = product.copyWith(isAvailable: product.isAvailable);
        _errorMessage = (result as ApiFailure).failure.message;
        notifyListeners();
      }
      return false;
    }

    return true;
  }

  /// حذف ناعم للمنتج
  Future<bool> deleteProduct(String productId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.softDeleteProduct(productId: productId);

    _isSaving = false;

    if (result is Success) {
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } else if (result is ApiFailure) {
      _errorMessage = (result as ApiFailure).failure.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return false;
  }

  /// تعيين نص البحث المحلي
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// تعيين التصنيف المحدد أو إلغاؤه
  void setSelectedCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null; // إلغاء التحديد إذا نُقر مجدداً
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }
}

