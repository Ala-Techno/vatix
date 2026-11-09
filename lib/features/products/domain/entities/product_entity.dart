import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/money_formatter.dart';

/// [ProductEntity] — كيان المنتج في نظام Vatix وفق المعيار §4.4
/// القواعد الصارمة:
/// 1. السعر [price] يُخزَّن دائماً كـ int بأصغر وحدة (Subunits) للعملة.
/// 2. العملة [currency] واحدة من 3 عملات فقط: YER, SAR, USD.
/// 3. الحذف ناعم [isActive]: عند حذفه يصبح false ويختفي من القوائم.
/// 4. التوفر [isAvailable]: إمكانية الطلب من قِبل التجار.
class ProductEntity {
  final String id;
  final String wholesalerId;
  final String name;
  final String? description;
  final int price; // بأصغر وحدة نقدية (subunits)
  final Currency currency;
  final String unit; // كرتون، حبة، باكت، كيس، كجم...
  final String? category;
  final String? imageUrl;
  final String? sku;
  final int? stockQuantity; // كمية العرض فقط (اختيارية)
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

  /// تنسيق سعر المنتج مع رمز العملة للعرض في الواجهة
  String get formattedPrice => MoneyFormatter.format(price, currency);

  /// هل المنتج غير متاح حالياً للطلب؟
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

/// نتيجة صفحة المنتجات مع المؤشر للصفحة التالية (Pagination)
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

