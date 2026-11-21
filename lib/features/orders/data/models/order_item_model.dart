import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/order_item_entity.dart';

/// [OrderItemModel] — Order item representation for serialization to and from Firestore
class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.productId,
    required super.name,
    required super.unit,
    required super.unitPrice,
    required super.currency,
    required super.quantity,
    required super.lineTotal,
    super.imageUrl,
    super.sku,
  });

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      productId: entity.productId,
      name: entity.name,
      unit: entity.unit,
      unitPrice: entity.unitPrice,
      currency: entity.currency,
      quantity: entity.quantity,
      lineTotal: entity.lineTotal,
      imageUrl: entity.imageUrl,
      sku: entity.sku,
    );
  }

  factory OrderItemModel.fromFirestoreMap(Map<String, dynamic> map) {
    final unitPrice = (map['unitPrice'] as num?)?.toInt() ?? 0;
    final quantity = (map['quantity'] as num?)?.toInt() ?? 1;
    final lineTotal =
        (map['lineTotal'] as num?)?.toInt() ?? (unitPrice * quantity);

    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      unitPrice: unitPrice,
      currency: Currency.fromString(map['currency'] as String? ?? 'YER'),
      quantity: quantity,
      lineTotal: lineTotal,
      imageUrl: map['imageUrl'] as String?,
      sku: map['sku'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'productId': productId,
      'name': name.trim(),
      'unit': unit.trim(),
      'unitPrice': unitPrice,
      'currency': currency.code,
      'quantity': quantity,
      'lineTotal': lineTotal,
      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'imageUrl': imageUrl!.trim(),
      if (sku != null && sku!.trim().isNotEmpty)
        'sku': sku!.trim().toUpperCase(),
    };
  }
}

