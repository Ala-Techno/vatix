import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';
import 'package:vatix/features/products/domain/entities/product_entity.dart';

/// [CartItemEntity] — Immutable snapshot of an item inside the shopping cart
/// Stores product info, unit price, quantity, and line total in smallest sub-units
class CartItemEntity {
  final String productId;
  final String wholesalerId;
  final String name;
  final String unit;
  final int unitPrice; // In smallest sub-units based on currency
  final Currency currency;
  final int quantity;
  final String? imageUrl;
  final String? category;
  final String? sku;

  const CartItemEntity({
    required this.productId,
    required this.wholesalerId,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.currency,
    required this.quantity,
    this.imageUrl,
    this.category,
    this.sku,
  });

  /// Create cart item snapshot directly from product entity
  factory CartItemEntity.fromProduct(ProductEntity product, {int quantity = 1}) {
    return CartItemEntity(
      productId: product.id,
      wholesalerId: product.wholesalerId,
      name: product.name,
      unit: product.unit,
      unitPrice: product.price,
      currency: product.currency,
      quantity: quantity.clamp(1, 999),
      imageUrl: product.imageUrl,
      category: product.category,
      sku: product.sku,
    );
  }

  /// Line total = unitPrice * quantity (in sub-units)
  int get lineTotal => unitPrice * quantity;

  /// Formatted unit price with currency symbol (e.g. 18,500 YER)
  String get formattedUnitPrice => MoneyFormatter.format(unitPrice, currency);

  /// Formatted line total with currency symbol
  String get formattedLineTotal => MoneyFormatter.format(lineTotal, currency);

  CartItemEntity copyWith({
    String? productId,
    String? wholesalerId,
    String? name,
    String? unit,
    int? unitPrice,
    Currency? currency,
    int? quantity,
    String? imageUrl,
    String? category,
    String? sku,
  }) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      sku: sku ?? this.sku,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemEntity &&
        other.productId == productId &&
        other.wholesalerId == wholesalerId &&
        other.name == name &&
        other.unit == unit &&
        other.unitPrice == unitPrice &&
        other.currency == currency &&
        other.quantity == quantity &&
        other.imageUrl == imageUrl &&
        other.category == category &&
        other.sku == sku;
  }

  @override
  int get hashCode => Object.hash(
        productId,
        wholesalerId,
        name,
        unit,
        unitPrice,
        currency,
        quantity,
        imageUrl,
        category,
        sku,
      );
}

