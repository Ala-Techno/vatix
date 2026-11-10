import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'cart_item_entity.dart';

/// نوع التغيير أو الفارق المكتشف في سلة المشتريات
enum DiscrepancyType {
  /// المنتج غير متاح حالياً للطلب أو تم تعطيله/حذفه من قبل المورد
  unavailableOrRemoved,

  /// تغير سعر الوحدة للمنتج
  priceChanged,

  /// تغير عملة البيع للمنتج
  currencyChanged,
}

/// تفاصيل الفارق لصنف محدد في السلة
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

  /// إنشاء فارغ عدم توفر
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

  /// إنشاء فارغ تغير السعر
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

  /// إنشاء فارغ تغير العملة
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

/// [CartValidationResult] — نتيجة إعادة التحقق من السلة قبل إرسال أمر الشراء
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

  /// نتيجة تطابق تام ولا توجد أي فروقات
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

