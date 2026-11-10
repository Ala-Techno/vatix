import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vatix/features/orders/domain/entities/order_entity.dart';
import 'package:vatix/features/orders/domain/repositories/orders_repository.dart';
import 'package:vatix/features/orders/domain/usecases/place_order_use_case.dart';

class FakeOrdersRepository implements OrdersRepository {
  OrderEntity? lastPlacedOrder;

  @override
  Future<ApiResult<OrderEntity>> placeOrder({required OrderEntity order}) async {
    lastPlacedOrder = order.copyWith(id: 'gen_order_123');
    return Success(lastPlacedOrder!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PlaceOrderUseCase Tests', () {
    late FakeOrdersRepository fakeRepo;
    late PlaceOrderUseCase useCase;
    final now = DateTime(2026, 3, 15);

    final retailerUser = UserEntity(
      id: 'retailer_1',
      role: UserRole.retailer,
      businessName: 'بقالة الفجر',
      ownerName: 'محمد أحمد',
      phone: '777000000',
      city: 'صنعاء',
      email: 'retailer@test.com',
      wholesalerId: 'wholesaler_1',
      status: RetailerStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    const cartItemYer = CartItemEntity(
      productId: 'p_yer',
      wholesalerId: 'wholesaler_1',
      name: 'أرز فاخر 10 كجم',
      unit: 'كيس',
      unitPrice: 24000,
      currency: Currency.yer,
      quantity: 2, // 48,000 YER
    );

    const cartItemSar = CartItemEntity(
      productId: 'p_sar',
      wholesalerId: 'wholesaler_1',
      name: 'زيت صافي 1.5 لتر',
      unit: 'كرتون',
      unitPrice: 5200,
      currency: Currency.sar,
      quantity: 3, // 15,600 SAR
    );

    const otherWholesalerItem = CartItemEntity(
      productId: 'p_other',
      wholesalerId: 'wholesaler_2', // مورد مختلف
      name: 'شاي ممتاز',
      unit: 'حبة',
      unitPrice: 1500,
      currency: Currency.yer,
      quantity: 1,
    );

    setUp(() {
      fakeRepo = FakeOrdersRepository();
      useCase = PlaceOrderUseCase(fakeRepo);
    });

    test('Rejects order if cart is empty', () async {
      final params = PlaceOrderParams(
        cartItems: const [],
        retailerUser: retailerUser,
        wholesalerName: 'شركة النور',
      );

      final result = await useCase(params);

      expect(result, isA<ApiFailure>());
      expect((result as ApiFailure).failure.message, contains('فارغة'));
    });

    test('Rejects order if retailer user has no wholesalerId', () async {
      final unlinkedUser = UserEntity(
        id: 'retailer_1',
        role: UserRole.retailer,
        businessName: 'بقالة الفجر',
        ownerName: 'محمد أحمد',
        phone: '777000000',
        city: 'صنعاء',
        email: 'retailer@test.com',
        wholesalerId: null,
        status: RetailerStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final params = PlaceOrderParams(
        cartItems: const [cartItemYer],
        retailerUser: unlinkedUser,
        wholesalerName: 'شركة النور',
      );

      final result = await useCase(params);

      expect(result, isA<ApiFailure>());
      expect((result as ApiFailure).failure.message, contains('غير مرتبط'));
    });

    test('Rejects order if an item belongs to a different wholesaler', () async {
      final params = PlaceOrderParams(
        cartItems: const [cartItemYer, otherWholesalerItem],
        retailerUser: retailerUser,
        wholesalerName: 'شركة النور',
      );

      final result = await useCase(params);

      expect(result, isA<ApiFailure>());
      expect((result as ApiFailure).failure.message, contains('لا تنتمي'));
    });

    test('Successfully builds order snapshot and computes multi-currency totals', () async {
      final params = PlaceOrderParams(
        cartItems: const [cartItemYer, cartItemSar],
        retailerUser: retailerUser,
        wholesalerName: 'شركة النور للمواد الغذائية',
        note: 'يرجى التأكد من تاريخ الإنتاج',
      );

      final result = await useCase(params);

      expect(result, isA<Success<OrderEntity>>());
      final order = (result as Success<OrderEntity>).data;

      expect(order.id, 'gen_order_123');
      expect(order.retailerId, 'retailer_1');
      expect(order.wholesalerId, 'wholesaler_1');
      expect(order.retailerName, 'بقالة الفجر');
      expect(order.wholesalerName, 'شركة النور للمواد الغذائية');
      expect(order.status, OrderStatus.pending);
      expect(order.note, 'يرجى التأكد من تاريخ الإنتاج');

      // Totals check
      expect(order.totals[Currency.yer], 48000);
      expect(order.totals[Currency.sar], 15600);

      // Items snapshot check
      expect(order.items.length, 2);
      expect(order.items[0].productId, 'p_yer');
      expect(order.items[0].lineTotal, 48000);
      expect(order.items[1].productId, 'p_sar');
      expect(order.items[1].lineTotal, 15600);
    });
  });
}
