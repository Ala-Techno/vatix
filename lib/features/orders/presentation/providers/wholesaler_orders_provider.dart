import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';

/// [WholesalerOrdersProvider] — Manages incoming orders state for wholesaler and dashboard
/// Uses live Streams for both pending orders and filtered orders list
class WholesalerOrdersProvider extends ChangeNotifier {
  final OrdersRepository _repository;

  WholesalerOrdersProvider({required OrdersRepository repository})
      : _repository = repository;

  String? _wholesalerId;

  // 1. Pending orders (Live Stream for Badge and Dashboard)
  List<OrderEntity> _pendingOrders = [];
  bool _isLoadingPending = true;
  StreamSubscription<List<OrderEntity>>? _pendingOrdersSub;

  // 2. Filtered orders list — Live Stream (replaces Pagination)
  OrderStatus? _selectedStatus; // null means "All"
  List<OrderEntity> _ordersList = [];
  bool _isLoadingOrders = false;
  String? _errorMessage;
  StreamSubscription<List<OrderEntity>>? _ordersListSub;

  // Getters
  List<OrderEntity> get pendingOrders => _pendingOrders;
  int get pendingCount => _pendingOrders.length;
  String get pendingCountBadge =>
      _pendingOrders.length >= 50 ? '50+' : '${_pendingOrders.length}';
  bool get isLoadingPending => _isLoadingPending;

  List<OrderEntity> get ordersList => _ordersList;
  OrderStatus? get selectedStatus => _selectedStatus;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingMore => false; // Live stream does not need isLoadingMore
  bool get hasMore => false; // Live stream fetches orders in one subscription
  String? get errorMessage => _errorMessage;

  /// Latest 5 incoming orders for Dashboard (Task 4.2.3)
  List<OrderEntity> get recentOrders => _pendingOrders.take(5).toList();

  /// Initializes both real-time listeners for the wholesaler
  void init(String wholesalerId) {
    if (_wholesalerId == wholesalerId) return;
    _wholesalerId = wholesalerId;

    // — Stream 1: Pending orders
    _isLoadingPending = true;
    _pendingOrdersSub?.cancel();
    _pendingOrdersSub = _repository
        .watchPendingOrdersForWholesaler(wholesalerId: wholesalerId, limit: 50)
        .listen(
      (orders) {
        _pendingOrders = orders;
        _isLoadingPending = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingPending = false;
        notifyListeners();
        if (kDebugMode) debugPrint('WholesalerOrdersProvider pending error: $e');
      },
    );

    // — Stream 2: Filtered orders list
    _startOrdersStream(status: _selectedStatus);
  }

  /// Starts (or restarts) live Stream for orders list based on status filter
  void _startOrdersStream({OrderStatus? status}) {
    if (_wholesalerId == null) return;

    _isLoadingOrders = true;
    _errorMessage = null;
    _ordersList = [];
    notifyListeners();

    _ordersListSub?.cancel();
    _ordersListSub = _repository
        .watchWholesalerOrders(
          wholesalerId: _wholesalerId!,
          status: status,
          limit: 50,
        )
        .listen(
      (orders) {
        _ordersList = orders;
        _isLoadingOrders = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoadingOrders = false;
        notifyListeners();
        if (kDebugMode) {
          debugPrint('WholesalerOrdersProvider orders error: $e');
        }
      },
    );
  }

  /// Updates status filter — automatically restarts a fresh stream
  void setStatusFilter(OrderStatus? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    _startOrdersStream(status: status);
  }

  /// Pull to refresh — live stream doesn't strictly need it, but retained for UI compatibility
  Future<void> refreshOrders() async {
    _startOrdersStream(status: _selectedStatus);
  }

  /// Backwards compatibility for any legacy loadOrders call from scroll listener
  Future<void> loadOrders({OrderStatus? status, bool refresh = false}) async {
    if (refresh) await refreshOrders();
    // Live stream: no pagination needed
  }

  @override
  void dispose() {
    _pendingOrdersSub?.cancel();
    _ordersListSub?.cancel();
    super.dispose();
  }
}
