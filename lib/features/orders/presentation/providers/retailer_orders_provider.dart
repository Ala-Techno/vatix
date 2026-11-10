import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/place_order_use_case.dart';

/// [RetailerOrdersProvider] — إدارة حالة طلبات التاجر والتفاعل معها لحظياً
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

  /// بدء الاستماع اللحظي لطلبات التاجر (Real-time Stream)
  void startListening(String retailerId) {
    if (_currentRetailerId == retailerId && _ordersSubscription != null) {
      return;
    }

    _currentRetailerId = retailerId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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

  /// إرسال أمر شراء جديد مع حارس ضد الضغط المزدوج
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

  /// إلغاء أمر شراء قيد الانتظار (Pending)
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

  /// استماع مباشر لطلب فردي (تفاصيل الطلب)
  Stream<OrderEntity?> watchSingleOrder(String orderId) {
    return _ordersRepository.watchOrder(orderId: orderId);
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
