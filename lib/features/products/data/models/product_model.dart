import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/product_entity.dart';

/// [ProductModel] — نموذج المنتج للتحويل من وإلى Firestore
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.wholesalerId,
    required super.name,
    super.description,
    required super.price,
    required super.currency,
    required super.unit,
    super.category,
    super.imageUrl,
    super.sku,
    super.stockQuantity,
    super.isAvailable = true,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  /// التحويل من مستند Firestore (باستخدام doc.id كمعرف للمنتج)
  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ProductModel(
      id: doc.id,
      wholesalerId: data['wholesalerId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      price: (data['price'] as num?)?.toInt() ?? 0,
      currency: Currency.tryFromString(data['currency']?.toString()) ??
          Currency.yer,
      unit: data['unit']?.toString() ?? '',
      category: data['category']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      sku: data['sku']?.toString(),
      stockQuantity: (data['stockQuantity'] as num?)?.toInt(),
      isAvailable: data['isAvailable'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// التحويل إلى خريطة (Map) لحفظها في Firestore
  Map<String, dynamic> toFirestoreMap({bool isCreate = false}) {
    final map = <String, dynamic>{
      'wholesalerId': wholesalerId,
      'name': name.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'price': price,
      'currency': currency.code,
      'unit': unit.trim(),
      'category': category?.trim().isEmpty == true ? null : category?.trim(),
      'imageUrl': imageUrl,
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim().toUpperCase(),
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }
}

