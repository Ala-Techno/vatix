import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/usecases/record_payment_use_case.dart';

/// [RetailerStatementProvider] — Manages statement view and payment processing (Tasks 5.3 & 5.4)
class RetailerStatementProvider extends ChangeNotifier {
  final LedgerRepository _repository;
  final RecordPaymentUseCase _recordPaymentUseCase;

  RetailerStatementProvider({
    required LedgerRepository repository,
    required RecordPaymentUseCase recordPaymentUseCase,
  })  : _repository = repository,
        _recordPaymentUseCase = recordPaymentUseCase;

  StreamSubscription<AccountEntity?>? _accountSub;
  AccountEntity? _account;

  String? _wholesalerId;
  String? _retailerId;

  // Statement state
  bool _isLoadingEntries = false;
  bool _isLoadingMore = false;
  String? _statementError;
  List<LedgerEntryEntity> _entries = [];
  dynamic _lastDocument;
  bool _hasMore = false;

  Currency? _selectedCurrency; // null = all

  // Payment process state (with double-tap guard)
  bool _isSubmittingPayment = false;
  String? _paymentError;

  // ─── Getters ─────────────────────────────────────────────────────────────

  AccountEntity? get account => _account;
  bool get isLoadingEntries => _isLoadingEntries;
  bool get isLoadingMore => _isLoadingMore;
  String? get statementError => _statementError;
  List<LedgerEntryEntity> get entries => _entries;
  bool get hasMore => _hasMore;
  Currency? get selectedCurrency => _selectedCurrency;
  bool get isSubmittingPayment => _isSubmittingPayment;
  String? get paymentError => _paymentError;

  // ─── Initialization ──────────────────────────────────────────────────────

  /// Initialize account listener and fetch first statement page
  void init({
    required String wholesalerId,
    required String retailerId,
    AccountEntity? initialAccount,
  }) {
    _wholesalerId = wholesalerId;
    _retailerId = retailerId;
    if (initialAccount != null) {
      _account = initialAccount;
    }

    // Real-time listener for account balance updates
    _accountSub?.cancel();
    _accountSub = _repository
        .watchAccount(wholesalerId: wholesalerId, retailerId: retailerId)
        .listen((acc) {
      if (acc != null) {
        _account = acc;
        notifyListeners();
      }
    });

    loadInitialStatement();
  }

  /// Load initial page of statement
  Future<void> loadInitialStatement() async {
    if (_wholesalerId == null || _retailerId == null) return;

    _isLoadingEntries = true;
    _statementError = null;
    notifyListeners();

    final result = await _repository.getStatement(
      wholesalerId: _wholesalerId!,
      retailerId: _retailerId!,
      currency: _selectedCurrency,
      limit: 20,
    );

    result.when(
      success: (page) {
        _entries = page.entries;
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoadingEntries = false;
        _statementError = null;
        notifyListeners();
      },
      failure: (failure) {
        _isLoadingEntries = false;
        _statementError = failure.message;
        notifyListeners();
      },
    );
  }

  /// Load next page (Pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    if (_wholesalerId == null || _retailerId == null) return;

    _isLoadingMore = true;
    notifyListeners();

    final result = await _repository.getStatement(
      wholesalerId: _wholesalerId!,
      retailerId: _retailerId!,
      currency: _selectedCurrency,
      limit: 20,
      startAfterDocument: _lastDocument,
    );

    result.when(
      success: (page) {
        _entries.addAll(page.entries);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        notifyListeners();
      },
      failure: (failure) {
        _isLoadingMore = false;
        notifyListeners();
      },
    );
  }

  /// Change currency filter and reload statement
  void setCurrencyFilter(Currency? currency) {
    if (_selectedCurrency != currency) {
      _selectedCurrency = currency;
      loadInitialStatement();
    }
  }

  /// Execute payment with double-tap guard (Task 5.4.3)
  Future<bool> recordPayment({
    required int amount,
    required Currency currency,
    required PaymentMethod method,
    String? reference,
    String? note,
    required String createdBy,
  }) async {
    if (_isSubmittingPayment) return false; // Double-tap guard
    if (_wholesalerId == null || _retailerId == null) return false;

    _isSubmittingPayment = true;
    _paymentError = null;
    notifyListeners();

    final retailerName = _account?.retailerName ?? '';

    final result = await _recordPaymentUseCase(
      wholesalerId: _wholesalerId!,
      retailerId: _retailerId!,
      retailerName: retailerName,
      amount: amount,
      currency: currency,
      method: method,
      reference: reference,
      note: note,
      createdBy: createdBy,
    );

    return result.when(
      success: (_) {
        _isSubmittingPayment = false;
        _paymentError = null;
        notifyListeners();

        // Immediately reload statement to show the new payment entry
        loadInitialStatement();
        return true;
      },
      failure: (failure) {
        _isSubmittingPayment = false;
        _paymentError = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  @override
  void dispose() {
    _accountSub?.cancel();
    super.dispose();
  }
}
