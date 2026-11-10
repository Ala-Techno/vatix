import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';

/// [OrderItemEntity] — لقطة ثابتة (Snapshot) لصنف داخل أمر الشراء
/// تحفظ السعر والوحدة والكمية والإجمالي وقت إرسال الطلب ولا تتأثر بتغير أسعار الكتالوج لاحقاً
class OrderItemEntity {
  final String productId;
  final String name;
  final String unit;
  final int unitPrice; // بأصغر وحدة (Subunits)
  final Currency currency;
  final int quantity;
  final int lineTotal; // unitPrice * quantity
  final String? imageUrl;
  final String? sku;

  const OrderItemEntity({
    required this.productId,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.currency,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
    this.sku,
  });

  /// إنشاء لقطة طلب من عنصر السلة مباشرة
  factory OrderItemEntity.fromCartItem(CartItemEntity cartItem) {
    return OrderItemEntity(
      productId: cartItem.productId,
      name: cartItem.name,
      unit: cartItem.unit,
      unitPrice: cartItem.unitPrice,
      currency: cartItem.currency,
      quantity: cartItem.quantity,
      lineTotal: cartItem.lineTotal,
      imageUrl: cartItem.imageUrl,
      sku: cartItem.sku,
    );
  }

  /// سعر الوحدة منسقاً
  String get formattedUnitPrice => MoneyFormatter.format(unitPrice, currency);

  /// إجمالي الصنف منسقاً
  String get formattedLineTotal => MoneyFormatter.format(lineTotal, currency);

  OrderItemEntity copyWith({
    String? productId,
    String? name,
    String? unit,
    int? unitPrice,
    Currency? currency,
    int? quantity,
    int? lineTotal,
    String? imageUrl,
    String? sku,
  }) {
    return OrderItemEntity(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
    );
  }
}

