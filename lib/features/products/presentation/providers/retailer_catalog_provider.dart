import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';

/// [RetailerCatalogProvider] — إدارة حالة كتالوج المنتجات المعروضة للتاجر
/// يعتمد على get() فقط (بدون Stream) مع دعم السحب للتحديث والـ Pagination
class RetailerCatalogProvider extends ChangeNotifier {
  final ProductsRepository _repository;

  RetailerCatalogProvider({required ProductsRepository repository})
      : _repository = repository;

  List<ProductEntity> _products = [];
  dynamic _lastDocument;
  bool _hasMore = true;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedCategory;
  bool _isGridView = false; // التبديل بين وضع الشبكة والقائمة

  // Getters
  List<ProductEntity> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get isGridView => _isGridView;

  /// استخراج التصنيفات المتاحة ديناميكياً من المنتجات المحملة
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
        final categoryMatch =
            p.category?.toLowerCase().contains(query) ?? false;
        return nameMatch || skuMatch || categoryMatch;
      }

      return true;
    }).toList();
  }

  /// تحميل أول صفحة من كتالوج مورد التاجر
  Future<void> loadCatalog({
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

    final result = await _repository.getRetailerProducts(
      wholesalerId: wholesalerId,
      limit: 20,
      startAfterDocument: null,
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

  /// تحميل الصفحة التالية عند التمرير
  Future<void> loadMoreCatalog({required String wholesalerId}) async {
    if (_isLoadingMore || !_hasMore || _isLoading || _lastDocument == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final result = await _repository.getRetailerProducts(
      wholesalerId: wholesalerId,
      limit: 20,
      startAfterDocument: _lastDocument,
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

  /// تعيين نص البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// اختيار التصنيف أو إلغاؤه
  void setSelectedCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  /// التبديل بين عرض الشبكة وعرض القائمة
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }
}

