import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/invite_code_entity.dart';
import '../../domain/repositories/customers_repository.dart';

class CustomersProvider extends ChangeNotifier {
  final CustomersRepository _repository;

  CustomersProvider({required CustomersRepository repository})
      : _repository = repository;

  String? _wholesalerId;

  // Real-time lists
  List<CustomerEntity> _pendingCustomers = [];
  List<CustomerEntity> _activeCustomers = [];
  List<CustomerEntity> _blockedCustomers = [];
  InviteCodeEntity? _activeInvite;

  bool _isLoadingCustomers = true;
  bool _isLoadingInvite = true;
  bool _isLoadingRotation = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  // Real-time subscriptions
  StreamSubscription<List<CustomerEntity>>? _pendingSub;
  StreamSubscription<List<CustomerEntity>>? _activeSub;
  StreamSubscription<List<CustomerEntity>>? _blockedSub;
  StreamSubscription<InviteCodeEntity?>? _inviteSub;

  // Getters
  List<CustomerEntity> get pendingCustomers => _pendingCustomers;
  List<CustomerEntity> get activeCustomers => _activeCustomers;
  List<CustomerEntity> get blockedCustomers => _blockedCustomers;
  InviteCodeEntity? get activeInvite => _activeInvite;

  int get pendingCount => _pendingCustomers.length;
  int get activeCount => _activeCustomers.length;
  int get blockedCount => _blockedCustomers.length;

  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isLoadingInvite => _isLoadingInvite;
  bool get isLoadingRotation => _isLoadingRotation;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  /// Initializes real-time listeners for wholesaler data
  void init(String wholesalerId) {
    if (_wholesalerId == wholesalerId) return;
    _wholesalerId = wholesalerId;

    _isLoadingCustomers = true;
    _isLoadingInvite = true;
    _cancelSubscriptions();

    // 1. Listen for join requests (pending)
    _pendingSub = _repository
        .watchCustomers(wholesalerId: wholesalerId, status: RetailerStatus.pending)
        .listen(
      (list) {
        _pendingCustomers = list;
        _isLoadingCustomers = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingCustomers = false;
        notifyListeners();
        if (kDebugMode) debugPrint('CustomersProvider pendingSub error: $e');
      },
    );

    // 2. Listen for active customers
    _activeSub = _repository
        .watchCustomers(wholesalerId: wholesalerId, status: RetailerStatus.active)
        .listen(
      (list) {
        _activeCustomers = list;
        _isLoadingCustomers = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingCustomers = false;
        notifyListeners();
        if (kDebugMode) debugPrint('CustomersProvider activeSub error: $e');
      },
    );

    // 3. Listen for blocked customers
    _blockedSub = _repository
        .watchCustomers(wholesalerId: wholesalerId, status: RetailerStatus.blocked)
        .listen(
      (list) {
        _blockedCustomers = list;
        _isLoadingCustomers = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingCustomers = false;
        notifyListeners();
        if (kDebugMode) debugPrint('CustomersProvider blockedSub error: $e');
      },
    );

    // 4. Listen for active invite code
    _inviteSub = _repository
        .watchActiveInvite(wholesalerId: wholesalerId)
        .listen(
      (invite) {
        _activeInvite = invite;
        _isLoadingInvite = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingInvite = false;
        notifyListeners();
        if (kDebugMode) debugPrint('CustomersProvider inviteSub error: $e');
      },
    );
  }

  /// Accepts customer join request (activates customer)
  Future<bool> acceptCustomer(String customerId) async {
    return _changeStatus(customerId, RetailerStatus.active);
  }

  /// Blocks a customer
  Future<bool> blockCustomer(String customerId) async {
    return _changeStatus(customerId, RetailerStatus.blocked);
  }

  /// Unblocks and reactivates a customer
  Future<bool> unblockCustomer(String customerId) async {
    return _changeStatus(customerId, RetailerStatus.active);
  }

  Future<bool> _changeStatus(String customerId, RetailerStatus status) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.setCustomerStatus(
      customerId: customerId,
      status: status,
    );

    _isActionLoading = false;
    if (result is ApiFailure) {
      _errorMessage = (result as ApiFailure).failure.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Rotates invite code (deactivates old code and creates a new one)
  Future<String?> rotateInvite() async {
    if (_wholesalerId == null) return null;

    _isLoadingRotation = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.rotateInvite(wholesalerId: _wholesalerId!);

    _isLoadingRotation = false;
    if (result is Success<String>) {
      notifyListeners();
      return result.data;
    } else if (result is ApiFailure<String>) {
      _errorMessage = result.failure.message;
      notifyListeners();
      return null;
    }

    notifyListeners();
    return null;
  }

  void _cancelSubscriptions() {
    _pendingSub?.cancel();
    _activeSub?.cancel();
    _blockedSub?.cancel();
    _inviteSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
