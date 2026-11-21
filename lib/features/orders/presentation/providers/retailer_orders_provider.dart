import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/place_order_use_case.dart';

/// [RetailerOrdersProvider] — State management for retailer orders and real-time interaction
class RetailerOrdersProvider extends ChangeNotifier {
  final OrdersRepository _ordersRepository;
  final PlaceOrderUseCase _placeOrderUseCase;

  RetailerOrdersProvider({
    required OrdersRepository ordersRepository,
    required PlaceOrderUseCase placeOrderUseCase,
  })  : _ordersRepository = ordersRepository,
        _placeOrderUseCase = placeOrderUseCase;

  List<OrderEntity> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPlacingOrder = false;
  bool _isCanceling = false;

  StreamSubscription<List<OrderEntity>>? _ordersSubscription;
  String? _currentRetailerId;

  // Getters
  List<OrderEntity> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isCanceling => _isCanceling;
  bool get hasOrders => _orders.isNotEmpty;

  /// Starts real-time stream for retailer orders
  void startListening(String retailerId, {bool force = false}) {
    if (retailerId.isEmpty) return;

    // Clean any prior subscription to establish a reliable fresh stream
    _currentRetailerId = retailerId;
    if (_orders.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;

    // Use microtask to avoid notifyListeners during build phase
    Future.microtask(() {
      notifyListeners();
    });

    _ordersSubscription?.cancel();
    _ordersSubscription = _ordersRepository
        .watchMyOrders(retailerId: retailerId)
        .listen(
      (ordersList) {
        _orders = ordersList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Resets state completely on logout
  void reset() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _currentRetailerId = null;
    _orders = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Forces reloading orders on pull-to-refresh
  Future<void> refreshOrders() async {
    if (_currentRetailerId != null && _currentRetailerId!.isNotEmpty) {
      startListening(_currentRetailerId!, force: true);
    }
  }

  /// Submits new purchase order with double-tap guard and immediate local insertion
  Future<ApiResult<OrderEntity>> placeOrder(PlaceOrderParams params) async {
    if (_isPlacingOrder) {
      return ApiFailure(
        const ValidationFailure('طلب الشراء قيد المعالجة بالفعل.'),
      );
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      final result = await _placeOrderUseCase(params);
      _isPlacingOrder = false;

      // Optimistic instant insertion into top of list so it appears immediately
      if (result is Success<OrderEntity>) {
        final newOrder = result.data;
        if (!_orders.any((o) => o.id == newOrder.id)) {
          _orders.insert(0, newOrder);
        }
      }

      notifyListeners();
      return result;
    } catch (e) {
      _isPlacingOrder = false;
      notifyListeners();
      return ApiFailure(
        ServerFailure('تعذّر إرسال أمر الشراء: $e'),
      );
    }
  }

  /// Cancels a pending purchase order
  Future<ApiResult<Unit>> cancelOrder({
    required String orderId,
    required String retailerId,
  }) async {
    if (_isCanceling) {
      return ApiFailure(
        const ValidationFailure('عملية الإلغاء جارية حالياً.'),
      );
    }

    _isCanceling = true;
    notifyListeners();

    final result = await _ordersRepository.cancelOrder(
      orderId: orderId,
      retailerId: retailerId,
    );

    _isCanceling = false;
    notifyListeners();
    return result;
  }

  /// Direct stream for single order details
  Stream<OrderEntity?> watchSingleOrder(String orderId) {
    return _ordersRepository.watchOrder(orderId: orderId);
  }

  /// Immediate local insertion of new order at the top of the list
  void addOrderLocally(OrderEntity order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index == -1) {
      _orders.insert(0, order);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Immediate local update of order status upon fetching or updating
  void updateOrderLocally(OrderEntity updatedOrder) {
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      if (_orders[index].status != updatedOrder.status ||
          _orders[index].updatedAt != updatedOrder.updatedAt) {
        _orders[index] = updatedOrder;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
