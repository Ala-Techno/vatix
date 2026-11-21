import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';

/// [ProductEntity] — Product entity in Vatix system per standard §4.4
/// Strict rules:
/// 1. Price [price] is always stored as int in the smallest currency unit (Subunits).
/// 2. Currency [currency] is strictly one of 3 currencies: YER, SAR, USD.
/// 3. Soft deletion [isActive]: when deleted, becomes false and hidden from lists.
/// 4. Availability [isAvailable]: orderability by retailers.
class ProductEntity {
  final String id;
  final String wholesalerId;
  final String name;
  final String? description;
  final int price; // In smallest currency unit (subunits)
  final Currency currency;
  final String unit; // Carton, piece, packet, bag, kg...
  final String? category;
  final String? imageUrl;
  final String? sku;
  final int? stockQuantity; // Display quantity only (optional)
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.wholesalerId,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    required this.unit,
    this.category,
    this.imageUrl,
    this.sku,
    this.stockQuantity,
    this.isAvailable = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted product price with currency symbol for UI display
  String get formattedPrice => MoneyFormatter.format(price, currency);

  /// Whether the product is currently unavailable for order
  bool get isUnavailable => !isAvailable;

  ProductEntity copyWith({
    String? id,
    String? wholesalerId,
    String? name,
    String? description,
    int? price,
    Currency? currency,
    String? unit,
    String? category,
    String? imageUrl,
    String? sku,
    int? stockQuantity,
    bool? isAvailable,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Products page result with cursor for subsequent page (Pagination)
class ProductsPageResult {
  final List<ProductEntity> products;
  final dynamic lastDocument; // DocumentSnapshot<Map<String, dynamic>>?
  final bool hasMore;

  const ProductsPageResult({
    required this.products,
    this.lastDocument,
    required this.hasMore,
  });
}

