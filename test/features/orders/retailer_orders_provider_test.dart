import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import 'package:vatix/features/cart/domain/entities/cart_item_entity.dart';
import 'package:vatix/features/orders/domain/entities/order_entity.dart';
import 'package:vatix/features/orders/domain/entities/order_item_entity.dart';
import 'package:vatix/features/orders/domain/repositories/orders_repository.dart';
import 'package:vatix/features/orders/domain/usecases/place_order_use_case.dart';
import 'package:vatix/features/orders/presentation/providers/retailer_orders_provider.dart';

class MockOrdersRepository implements OrdersRepository {
  final StreamController<List<OrderEntity>> ordersController =
      StreamController<List<OrderEntity>>.broadcast();

  OrderEntity? placedOrder;
  String? canceledOrderId;

  @override
  Stream<List<OrderEntity>> watchMyOrders({
    required String retailerId,
    int limit = 20,
  }) {
    return ordersController.stream;
  }

  @override
  Future<ApiResult<OrderEntity>> placeOrder({required OrderEntity order}) async {
    placedOrder = order.copyWith(id: 'order_gen_1');
    return Success(placedOrder!);
  }

  @override
  Future<ApiResult<Unit>> cancelOrder({
    required String orderId,
    required String retailerId,
  }) async {
    canceledOrderId = orderId;
    return const Success(Unit());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RetailerOrdersProvider Tests', () {
    late MockOrdersRepository mockRepo;
    late PlaceOrderUseCase placeOrderUseCase;
    late RetailerOrdersProvider provider;

    final now = DateTime(2026, 3, 15);

    final retailerUser = UserEntity(
      id: 'retailer_1',
      role: UserRole.retailer,
      businessName: 'بقالة النور',
      ownerName: 'علي يحيى',
      phone: '777111222',
      city: 'صنعاء',
      email: 'ali@test.com',
      wholesalerId: 'wholesaler_1',
      status: RetailerStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    final sampleOrder = OrderEntity(
      id: 'ord_123',
      retailerId: 'retailer_1',
      wholesalerId: 'wholesaler_1',
      retailerName: 'بقالة النور',
      wholesalerName: 'شركة البركة للتجارة',
      items: [
        OrderItemEntity(
          productId: 'prod_1',
          name: 'حليب ممتاز 1 لتر',
          unit: 'كرتون',
          unitPrice: 15000,
          currency: Currency.yer,
          quantity: 2,
          lineTotal: 30000,
        ),
      ],
      totals: const {Currency.yer: 30000},
      status: OrderStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      mockRepo = MockOrdersRepository();
      placeOrderUseCase = PlaceOrderUseCase(mockRepo);
      provider = RetailerOrdersProvider(
        ordersRepository: mockRepo,
        placeOrderUseCase: placeOrderUseCase,
      );
    });

    tearDown(() {
      provider.dispose();
      mockRepo.ordersController.close();
    });

    test('Initial state is empty and not loading', () {
      expect(provider.orders, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasOrders, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('startListening sets loading and receives orders from stream', () async {
      provider.startListening('retailer_1');
      expect(provider.isLoading, isTrue);

      // Emit orders
      mockRepo.ordersController.add([sampleOrder]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.isLoading, isFalse);
      expect(provider.hasOrders, isTrue);
      expect(provider.orders.length, equals(1));
      expect(provider.orders.first.id, equals('ord_123'));
      expect(provider.orders.first.shortId, equals('#ORD_12'));
    });

    test('placeOrder successfully executes and sets not placing when done', () async {
      final cartItem = CartItemEntity(
        productId: 'prod_1',
        wholesalerId: 'wholesaler_1',
        name: 'حليب ممتاز 1 لتر',
        unit: 'كرتون',
        unitPrice: 15000,
        currency: Currency.yer,
        quantity: 2,
      );

      final params = PlaceOrderParams(
        cartItems: [cartItem],
        retailerUser: retailerUser,
        wholesalerName: 'شركة البركة للتجارة',
      );

      final result = await provider.placeOrder(params);

      expect(result, isA<Success<OrderEntity>>());
      final created = (result as Success<OrderEntity>).data;
      expect(created.id, equals('order_gen_1'));
      expect(created.status, equals(OrderStatus.pending));
      expect(provider.isPlacingOrder, isFalse);
    });

    test('cancelOrder calls repository with orderId and retailerId', () async {
      final result = await provider.cancelOrder(
        orderId: 'ord_123',
        retailerId: 'retailer_1',
      );

      expect(result, isA<Success<Unit>>());
      expect(mockRepo.canceledOrderId, equals('ord_123'));
      expect(provider.isCanceling, isFalse);
    });
  });
}

