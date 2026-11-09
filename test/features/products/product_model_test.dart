import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/products/data/models/product_model.dart';

void main() {
  group('ProductEntity & ProductModel Tests', () {
    final now = DateTime(2026, 3, 15, 10, 0);

    final testProduct = ProductModel(
      id: 'prod_123',
      wholesalerId: 'wholesaler_abc',
      name: 'حليب ممتاز 390 جم',
      description: 'حليب مكثف محلى عالي الجودة',
      price: 18500, // 18,500 YER
      currency: Currency.yer,
      unit: 'كرتون',
      category: 'أغذية',
      imageUrl: 'https://example.com/milk.png',
      sku: 'MLK-01',
      stockQuantity: 50,
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    test('ProductEntity formattedPrice formats YER correctly', () {
      expect(testProduct.formattedPrice, '18,500 ر.ي');
    });

    test('ProductEntity formattedPrice formats SAR with 2 decimals correctly', () {
      final sarProduct = testProduct.copyWith(
        price: 5250, // 52.50 SAR
        currency: Currency.sar,
      );
      expect(sarProduct.formattedPrice, contains('52.50'));
      expect(sarProduct.formattedPrice, contains('ر.س'));
    });

    test('ProductEntity formattedPrice formats USD with 2 decimals correctly', () {
      final usdProduct = testProduct.copyWith(
        price: 99, // 0.99 USD
        currency: Currency.usd,
      );
      expect(usdProduct.formattedPrice, contains('0.99'));
      expect(usdProduct.formattedPrice, contains('\$'));
    });

    test('toFirestoreMap generates correct fields for Firestore', () {
      final map = testProduct.toFirestoreMap(isCreate: true);

      expect(map['wholesalerId'], 'wholesaler_abc');
      expect(map['name'], 'حليب ممتاز 390 جم');
      expect(map['price'], 18500);
      expect(map['currency'], 'YER');
      expect(map['unit'], 'كرتون');
      expect(map['sku'], 'MLK-01');
      expect(map['isAvailable'], true);
      expect(map['isActive'], true);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('toFirestoreMap trims strings and uppercases sku', () {
      final product = ProductModel(
        id: 'p1',
        wholesalerId: 'w1',
        name: '  أرز بسمتي  ',
        price: 25000,
        currency: Currency.yer,
        unit: '  شوالة  ',
        sku: '  rice-50kg  ',
        createdAt: now,
        updatedAt: now,
      );

      final map = product.toFirestoreMap(isCreate: false);

      expect(map['name'], 'أرز بسمتي');
      expect(map['unit'], 'شوالة');
      expect(map['sku'], 'RICE-50KG');
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('copyWith updates specified fields only', () {
      final updated = testProduct.copyWith(
        isAvailable: false,
        price: 20000,
      );

      expect(updated.id, testProduct.id);
      expect(updated.name, testProduct.name);
      expect(updated.price, 20000);
      expect(updated.isAvailable, isFalse);
      expect(updated.isUnavailable, isTrue);
    });
  });
}
