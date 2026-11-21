import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';

/// [WholesalerProductsProvider] — State management for wholesaler products
/// Supports: pagination, local search, category filtering, and immediate CRUD operations
class WholesalerProductsProvider extends ChangeNotifier {
  final ProductsRepository _repository;

  WholesalerProductsProvider({required ProductsRepository repository})
      : _repository = repository;

  List<ProductEntity> _products = [];
  dynamic _lastDocument;
  bool _hasMore = true;

  StreamSubscription<List<ProductEntity>>? _productsSubscription;

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

  /// Extracts unique categories from loaded products
  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      if (p.category != null && p.category!.trim().isNotEmpty) {
        set.add(p.category!.trim());
      }
    }
    return set.toList();
  }

  /// Filters products locally by name, SKU, and category
  List<ProductEntity> get filteredProducts {
    return _products.where((p) {
      // 1. Filter by category
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (p.category?.trim() != _selectedCategory!.trim()) {
          return false;
        }
      }

      // 2. Filter by search query
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

  /// Starts real-time stream of wholesaler products for automatic live updates
  void startListening({required String wholesalerId}) {
    if (wholesalerId.isEmpty) return;

    if (_products.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _productsSubscription?.cancel();
    _productsSubscription = _repository
        .watchWholesalerProducts(wholesalerId: wholesalerId, activeOnly: true)
        .listen(
      (productsList) {
        _products = List<ProductEntity>.from(productsList);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// Loads first page or refreshes list via pull-to-refresh
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
      _products = List<ProductEntity>.from(result.data.products);
      _lastDocument = result.data.lastDocument;
      _hasMore = result.data.hasMore;
    } else if (result is ApiFailure<ProductsPageResult>) {
      _errorMessage = result.failure.message;
    }

    notifyListeners();
  }

  /// Loads next page on downward scroll (Infinite Scroll)
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

  /// Adds a new product
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
      // Insert product at the beginning of the list directly
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

  /// Updates existing product data
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

  /// Toggles product availability for orders (quick switch)
  Future<bool> toggleAvailability(ProductEntity product) async {
    final newStatus = !product.isAvailable;

    // Fast optimistic UI update
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
      // Revert optimistic update on failure
      if (index != -1) {
        _products[index] = product.copyWith(isAvailable: product.isAvailable);
        _errorMessage = (result as ApiFailure).failure.message;
        notifyListeners();
      }
      return false;
    }

    return true;
  }

  /// Soft deletes a product
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

  /// Sets local search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Sets or clears selected category
  void setSelectedCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null; // Deselect if tapped again
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}

