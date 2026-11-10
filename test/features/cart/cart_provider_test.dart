import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vatix/features/cart/domain/entities/cart_validation_result.dart';
import 'package:vatix/features/cart/presentation/providers/cart_provider.dart';
import 'package:vatix/features/products/domain/entities/product_entity.dart';
import 'package:vatix/features/products/domain/repositories/products_repository.dart';

/// Fake implementation of ProductsRepository for testing Cart validation
class FakeProductsRepository implements ProductsRepository {
  final Map<String, ProductEntity> products = {};

  @override
  Future<ApiResult<ProductEntity>> getProductById({
    required String productId,
  }) async {
    final product = products[productId];
    if (product == null) {
      return ApiFailure(ServerFailure('المنتج غير موجود'));
    }
    return Success(product);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CartItemEntity Tests', () {
    final now = DateTime(2026, 3, 15);
    final product = ProductEntity(
      id: 'p1',
      wholesalerId: 'w1',
      name: 'حليب ممتاز',
      price: 18500, // 18,500 YER
      currency: Currency.yer,
      unit: 'كرتون',
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    test('lineTotal and formatted prices calculate correctly', () {
      final cartItem = CartItemEntity.fromProduct(product, quantity: 3);

      expect(cartItem.lineTotal, 18500 * 3);
      expect(cartItem.formattedUnitPrice, '18,500 ر.ي');
      expect(cartItem.formattedLineTotal, '55,500 ر.ي');
    });

    test('copyWith updates fields properly', () {
      final cartItem = CartItemEntity.fromProduct(product, quantity: 1);
      final updated = cartItem.copyWith(quantity: 5, unitPrice: 20000);

      expect(updated.quantity, 5);
      expect(updated.unitPrice, 20000);
      expect(updated.lineTotal, 100000);
    });
  });

  group('CartProvider Core Operations', () {
    late CartProvider cart;
    final now = DateTime(2026, 3, 15);

    final productYer = ProductEntity(
      id: 'p_yer',
      wholesalerId: 'w_alpha',
      name: 'أرز فاخر 10 كجم',
      price: 24000,
      currency: Currency.yer,
      unit: 'كيس',
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final productSar = ProductEntity(
      id: 'p_sar',
      wholesalerId: 'w_alpha',
      name: 'زيت صافي 1.5 لتر',
      price: 5200, // 52.00 SAR
      currency: Currency.sar,
      unit: 'كرتون',
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final otherWholesalerProduct = ProductEntity(
      id: 'p_beta',
      wholesalerId: 'w_beta',
      name: 'شاي ممتاز',
      price: 1500,
      currency: Currency.yer,
      unit: 'حبة',
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      cart = CartProvider();
    });

    test('Initial cart is empty', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.isNotEmpty, isFalse);
      expect(cart.itemCount, 0);
      expect(cart.uniqueItemCount, 0);
      expect(cart.totalsByCurrency.isEmpty, isTrue);
    });

    test('Adding product adds item and sets wholesaler lock', () {
      final error = cart.addItem(productYer, quantity: 2);

      expect(error, isNull);
      expect(cart.itemCount, 2);
      expect(cart.uniqueItemCount, 1);
      expect(cart.currentWholesalerId, 'w_alpha');
      expect(cart.isInCart('p_yer'), isTrue);
      expect(cart.getQuantity('p_yer'), 2);
    });

    test('Adding same product increases its quantity', () {
      cart.addItem(productYer, quantity: 2);
      cart.addItem(productYer, quantity: 3);

      expect(cart.itemCount, 5);
      expect(cart.uniqueItemCount, 1);
      expect(cart.getQuantity('p_yer'), 5);
    });

    test('Adding product from a different wholesaler is rejected (§3.1.4)', () {
      cart.addItem(productYer, quantity: 1);

      final error = cart.addItem(otherWholesalerProduct, quantity: 1);

      expect(error, contains('لا يمكن خلط أصناف من موردين مختلفين'));
      expect(cart.uniqueItemCount, 1);
      expect(cart.isInCart('p_beta'), isFalse);
    });

    test('Adding unavailable or inactive product is rejected', () {
      final unavailable = productYer.copyWith(isAvailable: false);
      final error = cart.addItem(unavailable);

      expect(error, contains('غير متاح للطلب'));
      expect(cart.isEmpty, isTrue);
    });

    test('Multi-currency totals are calculated independently (§3.1.3)', () {
      cart.addItem(productYer, quantity: 2); // 2 * 24,000 = 48,000 YER
      cart.addItem(productSar, quantity: 3); // 3 * 5,200 = 15,600 SAR

      expect(cart.itemCount, 5);
      expect(cart.uniqueItemCount, 2);

      final totals = cart.totalsByCurrency;
      expect(totals[Currency.yer], 48000);
      expect(totals[Currency.sar], 15600);
    });

    test('Increment, decrement, updateQuantity, and remove operations work', () {
      cart.addItem(productYer, quantity: 2);

      cart.increment('p_yer');
      expect(cart.getQuantity('p_yer'), 3);

      cart.decrement('p_yer');
      expect(cart.getQuantity('p_yer'), 2);

      cart.updateQuantity('p_yer', 10);
      expect(cart.getQuantity('p_yer'), 10);

      // Decrement to 0 removes the item
      cart.updateQuantity('p_yer', 1);
      cart.decrement('p_yer');
      expect(cart.isInCart('p_yer'), isFalse);
      expect(cart.isEmpty, isTrue);
      expect(cart.currentWholesalerId, isNull);
    });

    test('Clear resets all items and wholesaler lock', () {
      cart.addItem(productYer, quantity: 2);
      cart.addItem(productSar, quantity: 1);

      cart.clear();

      expect(cart.isEmpty, isTrue);
      expect(cart.currentWholesalerId, isNull);
    });
  });

  group('CartProvider Pre-checkout Re-validation (Task 3.2)', () {
    late CartProvider cart;
    late FakeProductsRepository fakeRepo;
    final now = DateTime(2026, 3, 15);

    final productA = ProductEntity(
      id: 'p_a',
      wholesalerId: 'w1',
      name: 'منتج أ',
      price: 1000,
      currency: Currency.yer,
      unit: 'حبة',
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final productB = ProductEntity(
      id: 'p_b',
      wholesalerId: 'w1',
      name: 'منتج ب',
      price: 2500,
      currency: Currency.yer,
      unit: 'حبة',
      isAvailable: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      cart = CartProvider();
      fakeRepo = FakeProductsRepository();

      fakeRepo.products['p_a'] = productA;
      fakeRepo.products['p_b'] = productB;
    });

    test('Validation passes cleanly when prices and availability match', () async {
      cart.addItem(productA, quantity: 2);
      cart.addItem(productB, quantity: 1);

      final result = await cart.validateCart(fakeRepo);

      expect(result.isValid, isTrue);
      expect(result.hasDiscrepancies, isFalse);
      expect(cart.uniqueItemCount, 2);
    });

    test('Detects price change and updates cart in-memory (§3.2.2 & 3.2.3)', () async {
      cart.addItem(productA, quantity: 2);

      // Wholesaler increased price from 1000 to 1200
      fakeRepo.products['p_a'] = productA.copyWith(price: 1200);

      final result = await cart.validateCart(fakeRepo);

      expect(result.isValid, isFalse);
      expect(result.hasDiscrepancies, isTrue);
      expect(result.discrepancies.length, 1);
      expect(result.discrepancies.first.type, DiscrepancyType.priceChanged);
      expect(result.discrepancies.first.oldPrice, 1000);
      expect(result.discrepancies.first.newPrice, 1200);

      // Cart price is updated in-memory
      expect(cart.items.first.unitPrice, 1200);
      expect(cart.totalsByCurrency[Currency.yer], 2400); // 2 * 1200
    });

    test('Detects unavailable product and removes it from cart (§3.2.4)', () async {
      cart.addItem(productA, quantity: 1);
      cart.addItem(productB, quantity: 1);

      // Wholesaler disabled product B
      fakeRepo.products['p_b'] = productB.copyWith(isAvailable: false);

      final result = await cart.validateCart(fakeRepo);

      expect(result.isValid, isFalse);
      expect(result.discrepancies.any((d) => d.productId == 'p_b'), isTrue);
      expect(result.removedProductIds, contains('p_b'));

      // Unavailable product B was removed from cart
      expect(cart.isInCart('p_b'), isFalse);
      expect(cart.isInCart('p_a'), isTrue);
      expect(cart.uniqueItemCount, 1);
    });

    test('Detects deleted product and removes it from cart', () async {
      cart.addItem(productA, quantity: 1);

      // Product deleted from repository
      fakeRepo.products.remove('p_a');

      final result = await cart.validateCart(fakeRepo);

      expect(result.isValid, isFalse);
      expect(result.removedProductIds, contains('p_a'));
      expect(cart.isEmpty, isTrue);
    });
  });
}
