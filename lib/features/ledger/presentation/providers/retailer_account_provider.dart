import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../../domain/repositories/ledger_repository.dart';

/// [RetailerAccountProvider] — إدارة حالة شاشة «حسابي» للتاجر (Task 5.5)
class RetailerAccountProvider extends ChangeNotifier {
  final LedgerRepository _repository;

  RetailerAccountProvider({required LedgerRepository repository})
      : _repository = repository;

  StreamSubscription<AccountEntity?>? _accountSub;
  AccountEntity? _account;
  String? _wholesalerId;
  String? _retailerId;

  // كشف حركات التاجر
  bool _isLoadingEntries = false;
  bool _isLoadingMore = false;
  String? _statementError;
  List<LedgerEntryEntity> _entries = [];
  dynamic _lastDocument;
  bool _hasMore = false;

  Currency? _selectedCurrency; // null = جميع العملات

  // ─── Getters ─────────────────────────────────────────────────────────────

  AccountEntity? get account => _account;
  bool get isLoadingEntries => _isLoadingEntries;
  bool get isLoadingMore => _isLoadingMore;
  String? get statementError => _statementError;
  List<LedgerEntryEntity> get entries => _entries;
  bool get hasMore => _hasMore;
  Currency? get selectedCurrency => _selectedCurrency;

  // ─── Methods ─────────────────────────────────────────────────────────────

  /// تهيئة وبدء الاستماع اللحظي لرصيد التاجر مع مورده وجلب أول صفحة من كشف الحساب
  void init({
    required String wholesalerId,
    required String retailerId,
  }) {
    if (_wholesalerId == wholesalerId &&
        _retailerId == retailerId &&
        _accountSub != null) {
      return;
    }

    _wholesalerId = wholesalerId;
    _retailerId = retailerId;

    // استماع لحظي لبطاقات الأرصدة (Task 5.5.1)
    _accountSub?.cancel();
    _accountSub = _repository
        .watchMyAccount(wholesalerId: wholesalerId, retailerId: retailerId)
        .listen((account) {
      _account = account;
      notifyListeners();
    });

    loadInitialStatement();
  }

  /// تحميل الصفحة الأولى من كشف الحركات (Task 5.5.2)
  Future<void> loadInitialStatement() async {
    if (_wholesalerId == null || _retailerId == null) return;

    _isLoadingEntries = true;
    _statementError = null;
    notifyListeners();

    final result = await _repository.getMyStatement(
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

  /// تحميل الصفحة التالية (Pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    if (_wholesalerId == null || _retailerId == null) return;

    _isLoadingMore = true;
    notifyListeners();

    final result = await _repository.getMyStatement(
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

  /// تصفية كشف الحساب بعملة محددة
  void setCurrencyFilter(Currency? currency) {
    if (_selectedCurrency != currency) {
      _selectedCurrency = currency;
      loadInitialStatement();
    }
  }

  @override
  void dispose() {
    _accountSub?.cancel();
    super.dispose();
  }
}

