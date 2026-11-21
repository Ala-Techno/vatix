import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/order_entity.dart';

/// [OrdersPageResult] — Result of fetching an orders page with pagination support
class OrdersPageResult {
  final List<OrderEntity> orders;
  final dynamic lastDocument;
  final bool hasMore;

  const OrdersPageResult({
    required this.orders,
    this.lastDocument,
    required this.hasMore,
  });
}

/// [OrdersRepository] — Domain contract for purchase order management
abstract class OrdersRepository {
  /// Submits a new purchase order and saves it as pending (with offline support E3)
  Future<ApiResult<OrderEntity>> placeOrder({
    required OrderEntity order,
  });

  /// Real-time stream of retailer orders list
  Stream<List<OrderEntity>> watchMyOrders({
    required String retailerId,
    int limit = 20,
  });

  /// Fetches an additional page of orders with pagination
  Future<ApiResult<OrdersPageResult>> getMyOrdersPage({
    required String retailerId,
    int limit = 20,
    dynamic startAfterDocument,
  });

  /// Real-time stream of specific order details and status
  Stream<OrderEntity?> watchOrder({
    required String orderId,
  });

  /// Cancels an order by retailer (permitted only in pending status)
  Future<ApiResult<Unit>> cancelOrder({
    required String orderId,
    required String retailerId,
  });

  /// Real-time stream of pending orders for wholesaler (max 50) for Dashboard and Badge
  Stream<List<OrderEntity>> watchPendingOrdersForWholesaler({
    required String wholesalerId,
    int limit = 50,
  });

  /// Real-time stream of wholesaler orders filtered by status
  Stream<List<OrderEntity>> watchWholesalerOrders({
    required String wholesalerId,
    OrderStatus? status,
    int limit = 50,
  });

  /// Fetches a page of incoming wholesaler orders with pagination and optional status filter
  Future<ApiResult<OrdersPageResult>> getWholesalerOrdersPage({
    required String wholesalerId,
    OrderStatus? status,
    int limit = 20,
    dynamic startAfterDocument,
  });

  /// Atomically approves purchase order, writes ledger entries, and updates accounts (Task 4.5)
  Future<ApiResult<Unit>> approveOrder({
    required OrderEntity order,
    required PaymentType paymentType,
    required String currentUid,
  });

  /// Rejects purchase order with a mandatory reason (Task 4.6.1)
  Future<ApiResult<Unit>> rejectOrder({
    required String orderId,
    required String rejectionReason,
  });

  /// Confirms delivery of purchase order to retailer (Task 4.6.2)
  Future<ApiResult<Unit>> deliverOrder({
    required String orderId,
  });
}

