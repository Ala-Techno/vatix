import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';

/// [WholesalerOrdersProvider] — يدير حالة الطلبات الواردة للمورد ولوحة التحكم
class WholesalerOrdersProvider extends ChangeNotifier {
  final OrdersRepository _repository;

  WholesalerOrdersProvider({required OrdersRepository repository})
      : _repository = repository;

  String? _wholesalerId;

  // 1. الطلبات المعلقة (Stream حي مع limit 50 للـ Dashboard والـ Badge)
  List<OrderEntity> _pendingOrders = [];
  bool _isLoadingPending = true;
  StreamSubscription<List<OrderEntity>>? _pendingOrdersSub;

  // 2. قائمة الطلبات المفلترة والمقسّمة صفحات (Pagination)
  OrderStatus? _selectedStatus; // null تعني "الكل"
  List<OrderEntity> _ordersList = [];
  bool _isLoadingOrders = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  dynamic _lastDocument;
  String? _errorMessage;

  // Getters
  List<OrderEntity> get pendingOrders => _pendingOrders;
  int get pendingCount => _pendingOrders.length;
  String get pendingCountBadge => _pendingOrders.length >= 50 ? '50+' : '${_pendingOrders.length}';
  bool get isLoadingPending => _isLoadingPending;

  List<OrderEntity> get ordersList => _ordersList;
  OrderStatus? get selectedStatus => _selectedStatus;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// آخر 5 طلبات واردة للـ Dashboard (Task 4.2.3)
  List<OrderEntity> get recentOrders => _pendingOrders.take(5).toList();

  /// تهيئة المستمع اللحظي للـ pending orders للمورد
  void init(String wholesalerId) {
    if (_wholesalerId == wholesalerId) return;
    _wholesalerId = wholesalerId;

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

    // استخدام Future.microtask لضمان عدم استدعاء notifyListeners أثناء دورة البناء (Build Phase)
    Future.microtask(() {
      loadOrders(status: _selectedStatus, refresh: true);
    });
  }

  /// تغيير فلتر الحالة وتحميل الطلبات
  void setStatusFilter(OrderStatus? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadOrders(status: status, refresh: true);
  }

  /// جلب الطلبات الواردة مع الـ Pagination
  Future<void> loadOrders({OrderStatus? status, bool refresh = false}) async {
    if (_wholesalerId == null) return;
    if (_isLoadingOrders || (_isLoadingMore && !refresh)) return;

    if (refresh) {
      _isLoadingOrders = true;
      _errorMessage = null;
      _hasMore = true;
      _lastDocument = null;
      notifyListeners();
    } else {
      if (!_hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final result = await _repository.getWholesalerOrdersPage(
      wholesalerId: _wholesalerId!,
      status: status ?? _selectedStatus,
      limit: 20,
      startAfterDocument: refresh ? null : _lastDocument,
    );

    result.when(
      success: (pageResult) {
        if (refresh) {
          _ordersList = pageResult.orders;
        } else {
          _ordersList.addAll(pageResult.orders);
        }
        _lastDocument = pageResult.lastDocument;
        _hasMore = pageResult.hasMore;
        _isLoadingOrders = false;
        _isLoadingMore = false;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isLoadingOrders = false;
        _isLoadingMore = false;
        notifyListeners();
      },
    );
  }

  /// سحب للتحديث
  Future<void> refreshOrders() async {
    await loadOrders(status: _selectedStatus, refresh: true);
  }

  @override
  void dispose() {
    _pendingOrdersSub?.cancel();
    super.dispose();
  }
}

