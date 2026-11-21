import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vatix/features/cart/domain/entities/cart_validation_result.dart';
import 'package:vatix/features/products/domain/entities/product_entity.dart';
import 'package:vatix/features/products/domain/repositories/products_repository.dart';

/// [CartProvider] — In-memory cart state management for retailer.
/// Supports: multi-currency, single-wholesaler locking, real-time re-validation before checkout.
class CartProvider extends ChangeNotifier {
  final Map<String, CartItemEntity> _items = {};
  String? _currentWholesalerId;
  bool _isValidating = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  /// Current cart items list.
  List<CartItemEntity> get items => _items.values.toList();

  /// Total count of pieces in cart (sum of quantities).
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Count of unique items in cart.
  int get uniqueItemCount => _items.length;

  /// Whether the cart is empty.
  bool get isEmpty => _items.isEmpty;

  /// Whether the cart has items.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Wholesaler ID to which the current cart is locked.
  String? get currentWholesalerId => _currentWholesalerId;

  /// Whether re-validation is in progress.
  bool get isValidating => _isValidating;

  /// Calculates cart total grouped by currency (Subunits).
  /// Example: {Currency.yer: 45000, Currency.sar: 1200}
  Map<Currency, int> get totalsByCurrency {
    final totals = <Currency, int>{};
    for (final item in _items.values) {
      totals[item.currency] = (totals[item.currency] ?? 0) + item.lineTotal;
    }
    return totals;
  }

  /// Checks whether a given product exists in the cart.
  bool isInCart(String productId) => _items.containsKey(productId);

  /// Gets the quantity of a given product in the cart.
  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  // ── Cart Operations ────────────────────────────────────────────────────────

  /// Adds an item to the cart or increments its quantity if already present.
  /// Returns [String?] containing error message on failure, or null on success.
  String? addItem(ProductEntity product, {int quantity = 1}) {
    // 1. Validate product availability and active status
    if (!product.isActive || !product.isAvailable) {
      return 'عذراً، هذا الصنف غير متاح للطلب حالياً لدى المورد.';
    }

    // 2. Validate single wholesaler locking (M3 §3.1.4: no mixing between different companies)
    if (_currentWholesalerId != null &&
        _currentWholesalerId != product.wholesalerId) {
      return 'لا يمكن خلط أصناف من موردين مختلفين في نفس السلة. تفريغ السلة مطلوب أولاً.';
    }

    // Assign wholesaler if cart was empty
    _currentWholesalerId = product.wholesalerId;

    final existing = _items[product.id];
    if (existing != null) {
      final newQuantity = (existing.quantity + quantity).clamp(1, 999);
      _items[product.id] = existing.copyWith(
        quantity: newQuantity,
        unitPrice: product.price,
        currency: product.currency,
        name: product.name,
        unit: product.unit,
      );
    } else {
      _items[product.id] = CartItemEntity.fromProduct(
        product,
        quantity: quantity,
      );
    }

    notifyListeners();
    return null;
  }

  /// Increments item quantity by one.
  void increment(String productId) {
    final existing = _items[productId];
    if (existing == null) return;
    if (existing.quantity >= 999) return;

    _items[productId] = existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
  }

  /// Decrements item quantity by one (removes item if quantity reaches zero).
  void decrement(String productId) {
    final existing = _items[productId];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      removeItem(productId);
    } else {
      _items[productId] = existing.copyWith(quantity: existing.quantity - 1);
      notifyListeners();
    }
  }

  /// Sets specific quantity for an item directly.
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final existing = _items[productId];
    if (existing == null) return;

    _items[productId] = existing.copyWith(quantity: newQuantity.clamp(1, 999));
    notifyListeners();
  }

  /// Removes an item from the cart.
  void removeItem(String productId) {
    final removed = _items.remove(productId);
    if (removed != null) {
      if (_items.isEmpty) {
        _currentWholesalerId = null;
      }
      notifyListeners();
    }
  }

  /// Clears the entire cart.
  void clear() {
    _items.clear();
    _currentWholesalerId = null;
    notifyListeners();
  }

  // ── Pre-checkout Re-validation (Task 3.2) ───────────────────────────────────

  /// Fresh validation of validity, prices, and availability of all cart items against Firestore.
  Future<CartValidationResult> validateCart(ProductsRepository repository) async {
    if (_items.isEmpty) {
      return CartValidationResult.clean();
    }

    _isValidating = true;
    notifyListeners();

    final discrepancies = <CartItemDiscrepancy>[];
    final removedIds = <String>[];
    final updatedList = <CartItemEntity>[];

    try {
      final currentEntries = Map<String, CartItemEntity>.from(_items);

      for (final entry in currentEntries.entries) {
        final productId = entry.key;
        final cartItem = entry.value;

        final result = await repository.getProductById(productId: productId);

        if (result is ApiFailure) {
          final failure = (result as ApiFailure).failure;
          // Product actually deleted from database
          final isNotFound = failure.message.contains('غير موجود') ||
              failure.message.contains('not-found');
          if (isNotFound) {
            discrepancies.add(
              CartItemDiscrepancy.unavailable(
                productId: productId,
                productName: cartItem.name,
              ),
            );
            removedIds.add(productId);
            _items.remove(productId);
          }
          // On network loss (Offline E3), keep cart items and continue
          continue;
        }

        final freshProduct = (result as Success<ProductEntity>).data;

        // 1. Check availability and active status
        if (!freshProduct.isActive || !freshProduct.isAvailable) {
          discrepancies.add(
            CartItemDiscrepancy.unavailable(
              productId: productId,
              productName: freshProduct.name,
            ),
          );
          removedIds.add(productId);
          _items.remove(productId);
          continue;
        }

        // 2. Check currency change
        if (freshProduct.currency != cartItem.currency) {
          discrepancies.add(
            CartItemDiscrepancy.currencyChanged(
              productId: productId,
              productName: freshProduct.name,
              oldPrice: cartItem.unitPrice,
              oldCurrency: cartItem.currency,
              newPrice: freshProduct.price,
              newCurrency: freshProduct.currency,
            ),
          );
          final updated = cartItem.copyWith(
            unitPrice: freshProduct.price,
            currency: freshProduct.currency,
            name: freshProduct.name,
            unit: freshProduct.unit,
            imageUrl: freshProduct.imageUrl,
            category: freshProduct.category,
            sku: freshProduct.sku,
          );
          _items[productId] = updated;
          updatedList.add(updated);
          continue;
        }

        // 3. Check price change
        if (freshProduct.price != cartItem.unitPrice) {
          discrepancies.add(
            CartItemDiscrepancy.priceChanged(
              productId: productId,
              productName: freshProduct.name,
              oldPrice: cartItem.unitPrice,
              newPrice: freshProduct.price,
              currency: freshProduct.currency,
            ),
          );
          final updated = cartItem.copyWith(
            unitPrice: freshProduct.price,
            name: freshProduct.name,
            unit: freshProduct.unit,
            imageUrl: freshProduct.imageUrl,
            category: freshProduct.category,
            sku: freshProduct.sku,
          );
          _items[productId] = updated;
          updatedList.add(updated);
          continue;
        }

        // 4. Update minor text details (name, unit, image, SKU)
        final updated = cartItem.copyWith(
          name: freshProduct.name,
          unit: freshProduct.unit,
          imageUrl: freshProduct.imageUrl,
          category: freshProduct.category,
          sku: freshProduct.sku,
        );
        _items[productId] = updated;
      }

      if (_items.isEmpty) {
        _currentWholesalerId = null;
      }

      final validationResult = CartValidationResult(
        isValid: discrepancies.isEmpty,
        discrepancies: discrepancies,
        removedProductIds: removedIds,
        updatedItems: updatedList,
      );

      return validationResult;
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }
}

