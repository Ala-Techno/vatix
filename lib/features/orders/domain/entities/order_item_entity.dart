import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';

/// [OrderItemEntity] — Immutable snapshot of an item inside a purchase order.
/// Preserves price, unit, quantity, and line total at order placement time and is unaffected by later catalog changes.
class OrderItemEntity {
  final String productId;
  final String name;
  final String unit;
  final int unitPrice; // In subunits
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

  /// Creates an order item snapshot directly from a cart item
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

  /// Formatted unit price
  String get formattedUnitPrice => MoneyFormatter.format(unitPrice, currency);

  /// Formatted line total
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

