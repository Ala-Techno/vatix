import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vatix/features/cart/domain/entities/cart_validation_result.dart';
import 'package:vatix/features/products/domain/entities/product_entity.dart';
import 'package:vatix/features/products/domain/repositories/products_repository.dart';

/// [CartProvider] — إدارة حالة سلة المشتريات المحلية في الذاكرة لتاجر التجزئة
/// تدعم: العملات المتعددة، قفل المورد الواحد، إعادة التحقق اللحظي قبل إرسال الطلب
class CartProvider extends ChangeNotifier {
  final Map<String, CartItemEntity> _items = {};
  String? _currentWholesalerId;
  bool _isValidating = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  /// قائمة العناصر الحالية بالسلة
  List<CartItemEntity> get items => _items.values.toList();

  /// إجمالي عدد القطع بالسلة (مجموع الكميات)
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// عدد الأصناف الفريدة بالسلة
  int get uniqueItemCount => _items.length;

  /// هل السلة فارغة
  bool get isEmpty => _items.isEmpty;

  /// هل السلة تحوي عناصر
  bool get isNotEmpty => _items.isNotEmpty;

  /// معرف المورد المقفلة عليه السلة الحالية
  String? get currentWholesalerId => _currentWholesalerId;

  /// هل عملية إعادة التحقق جارية
  bool get isValidating => _isValidating;

  /// حساب إجمالي السلة مجمّعاً حسب كل عملة (Subunits)
  /// مثال: {Currency.yer: 45000, Currency.sar: 1200}
  Map<Currency, int> get totalsByCurrency {
    final totals = <Currency, int>{};
    for (final item in _items.values) {
      totals[item.currency] = (totals[item.currency] ?? 0) + item.lineTotal;
    }
    return totals;
  }

  /// التحقق إن كان منتج معين موجوداً في السلة
  bool isInCart(String productId) => _items.containsKey(productId);

  /// الحصول على كمية منتج معين في السلة
  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  // ── العمليات الأساسية (Cart Operations) ──────────────────────────────────────

  /// إضافة صنف للسلة أو زيادة كميته إن كان موجوداً مسبقاً
  /// تعيد [String?] يحوي رسالة الخطأ في حال الفشل، أو null عند النجاح
  String? addItem(ProductEntity product, {int quantity = 1}) {
    // 1. التحقق من توفر ونشاط المنتج
    if (!product.isActive || !product.isAvailable) {
      return 'عذراً، هذا الصنف غير متاح للطلب حالياً لدى المورد.';
    }

    // 2. التحقق من قفل المورد (M3 §3.1.4: لا خلط بين شركات مختلفة)
    if (_currentWholesalerId != null &&
        _currentWholesalerId != product.wholesalerId) {
      return 'لا يمكن خلط أصناف من موردين مختلفين في نفس السلة. تفريغ السلة مطلوب أولاً.';
    }

    // تعيين المورد إن كانت السلة فارغة
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

  /// زيادة كمية صنف بواحد
  void increment(String productId) {
    final existing = _items[productId];
    if (existing == null) return;
    if (existing.quantity >= 999) return;

    _items[productId] = existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
  }

  /// إنقاص كمية صنف بواحد (وإزالته إذا وصلت للصفر)
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

  /// تعيين كمية محددة لصنف مباشرة
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

  /// حذف صنف من السلة
  void removeItem(String productId) {
    final removed = _items.remove(productId);
    if (removed != null) {
      if (_items.isEmpty) {
        _currentWholesalerId = null;
      }
      notifyListeners();
    }
  }

  /// تفريغ السلة بالكامل
  void clear() {
    _items.clear();
    _currentWholesalerId = null;
    notifyListeners();
  }

  // ── إعادة التحقق قبل الإرسال (Task 3.2: Pre-checkout Re-validation) ──────────

  /// التحقق من صلاحية وأسعار وتوفر جميع أصناف السلة حديثاً من Firestore
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
          // المنتج محذوف فعلياً من قاعدة البيانات
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
          // في حال عدم توفر اتصال بالشبكة (Offline E3) نحافظ على عناصر السلة ونتابع
          continue;
        }

        final freshProduct = (result as Success<ProductEntity>).data;

        // 1. فحص التوفر والنشاط
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

        // 2. فحص تغير العملة
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

        // 3. فحص تغير السعر
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

        // 4. تحديث أي تفاصيل نصية طفيفة (الاسم أو الوحدة أو الصورة)
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

