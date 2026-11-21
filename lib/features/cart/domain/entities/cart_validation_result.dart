import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'cart_item_entity.dart';

/// Discrepancy type detected in shopping cart items prior to checkout
enum DiscrepancyType {
  /// Product is unavailable or deactivated/deleted by wholesaler
  unavailableOrRemoved,

  /// Product unit price changed
  priceChanged,

  /// Product sales currency changed
  currencyChanged,
}

/// Discrepancy details for a specific item in cart
class CartItemDiscrepancy {
  final String productId;
  final String productName;
  final DiscrepancyType type;
  final String message;
  final int? oldPrice;
  final int? newPrice;
  final Currency? oldCurrency;
  final Currency? newCurrency;

  const CartItemDiscrepancy({
    required this.productId,
    required this.productName,
    required this.type,
    required this.message,
    this.oldPrice,
    this.newPrice,
    this.oldCurrency,
    this.newCurrency,
  });

  /// Factory for unavailable product discrepancy
  factory CartItemDiscrepancy.unavailable({
    required String productId,
    required String productName,
  }) {
    return CartItemDiscrepancy(
      productId: productId,
      productName: productName,
      type: DiscrepancyType.unavailableOrRemoved,
      message: 'الصنف «$productName» لم يعد متوفراً لدى المورد وتم حذفه من السلة.',
    );
  }

  /// Factory for price change discrepancy
  factory CartItemDiscrepancy.priceChanged({
    required String productId,
    required String productName,
    required int oldPrice,
    required int newPrice,
    required Currency currency,
  }) {
    final oldFormatted = MoneyFormatter.format(oldPrice, currency);
    final newFormatted = MoneyFormatter.format(newPrice, currency);
    return CartItemDiscrepancy(
      productId: productId,
      productName: productName,
      type: DiscrepancyType.priceChanged,
      oldPrice: oldPrice,
      newPrice: newPrice,
      oldCurrency: currency,
      newCurrency: currency,
      message:
          'تم تحديث سعر «$productName» من $oldFormatted إلى $newFormatted.',
    );
  }

  /// Factory for currency change discrepancy
  factory CartItemDiscrepancy.currencyChanged({
    required String productId,
    required String productName,
    required int oldPrice,
    required Currency oldCurrency,
    required int newPrice,
    required Currency newCurrency,
  }) {
    final oldFormatted = MoneyFormatter.format(oldPrice, oldCurrency);
    final newFormatted = MoneyFormatter.format(newPrice, newCurrency);
    return CartItemDiscrepancy(
      productId: productId,
      productName: productName,
      type: DiscrepancyType.currencyChanged,
      oldPrice: oldPrice,
      newPrice: newPrice,
      oldCurrency: oldCurrency,
      newCurrency: newCurrency,
      message:
          'تغيرت عملة وسعر «$productName» من $oldFormatted إلى $newFormatted.',
    );
  }
}

/// [CartValidationResult] — Result of re-validating cart items prior to placing order
class CartValidationResult {
  final bool isValid;
  final List<CartItemDiscrepancy> discrepancies;
  final List<String> removedProductIds;
  final List<CartItemEntity> updatedItems;

  const CartValidationResult({
    required this.isValid,
    required this.discrepancies,
    required this.removedProductIds,
    required this.updatedItems,
  });

  /// Clean validation result with zero discrepancies
  factory CartValidationResult.clean() {
    return const CartValidationResult(
      isValid: true,
      discrepancies: [],
      removedProductIds: [],
      updatedItems: [],
    );
  }

  bool get hasDiscrepancies => discrepancies.isNotEmpty;
}

