import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/ledger_repository.dart';

/// [LedgerFilterMode] — Account list filtering mode
enum LedgerFilterMode {
  all('الكل'),
  withDebt('عليهم ديون'),
  settled('مصفّر');

  final String label;
  const LedgerFilterMode(this.label);
}

/// [WholesalerLedgerProvider] — State management for wholesaler debts and accounts ledger (Task 5.2)
class WholesalerLedgerProvider extends ChangeNotifier {
  final LedgerRepository _repository;

  WholesalerLedgerProvider({required LedgerRepository repository})
      : _repository = repository;

  StreamSubscription<List<AccountEntity>>? _accountsSub;
  String? _currentWholesalerId;

  bool _isLoading = false;
  String? _errorMessage;
  List<AccountEntity> _accounts = [];

  String _searchQuery = '';
  LedgerFilterMode _filterMode = LedgerFilterMode.all;

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AccountEntity> get accounts => _accounts;
  String get searchQuery => _searchQuery;
  LedgerFilterMode get filterMode => _filterMode;

  /// Filtered accounts according to search query and mode, sorted by highest debt
  List<AccountEntity> get filteredAccounts {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _accounts.where((account) {
      // 1. Search by name
      if (query.isNotEmpty) {
        final matchesName =
            account.retailerName.toLowerCase().contains(query);
        if (!matchesName) return false;
      }

      // 2. Debt status filter
      switch (_filterMode) {
        case LedgerFilterMode.all:
          return true;
        case LedgerFilterMode.withDebt:
          return account.hasDebt;
        case LedgerFilterMode.settled:
          return account.isSettled;
      }
    }).toList();

    // 3. Sorting: highest debt first (comparing positive debt balance sums)
    filtered.sort((a, b) {
      final aHasDebt = a.hasDebt;
      final bHasDebt = b.hasDebt;
      if (aHasDebt && !bHasDebt) return -1;
      if (!aHasDebt && bHasDebt) return 1;

      // Compare total debt amounts
      final sumA = a.balances.values.fold<int>(0, (prev, val) => prev + (val > 0 ? val : 0));
      final sumB = b.balances.values.fold<int>(0, (prev, val) => prev + (val > 0 ? val : 0));
      return sumB.compareTo(sumA);
    });

    return filtered;
  }

  /// Total receivables and outstanding debt per currency (Task 5.2.3)
  Map<Currency, int> get totalReceivables {
    final Map<Currency, int> totals = {
      Currency.yer: 0,
      Currency.sar: 0,
      Currency.usd: 0,
    };

    for (final account in _accounts) {
      for (final entry in account.balances.entries) {
        if (entry.value > 0) {
          totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
        }
      }
    }

    return totals;
  }

  /// Whether there is any outstanding debt across any currency
  bool get hasAnyReceivables =>
      totalReceivables.values.any((amount) => amount > 0);

  // ─── Methods ─────────────────────────────────────────────────────────────

  /// Start real-time listening to accounts when screen opens
  void init(String wholesalerId) {
    if (_currentWholesalerId == wholesalerId && _accountsSub != null) return;
    _currentWholesalerId = wholesalerId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _accountsSub?.cancel();
    _accountsSub = _repository
        .watchAccounts(wholesalerId: wholesalerId, limit: 100)
        .listen(
      (data) {
        _accounts = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _errorMessage = 'تعذّر جلب حسابات الدفتر: $err';
        notifyListeners();
      },
    );
  }

  /// Update search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Change accounts filter mode
  void setFilterMode(LedgerFilterMode mode) {
    if (_filterMode != mode) {
      _filterMode = mode;
      notifyListeners();
    }
  }

  /// Retry upon error
  void retry() {
    if (_currentWholesalerId != null) {
      final wid = _currentWholesalerId!;
      _currentWholesalerId = null;
      init(wid);
    }
  }

  @override
  void dispose() {
    _accountsSub?.cancel();
    super.dispose();
  }
}
