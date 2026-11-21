import 'package:vatix/core/utils/currency.dart';
import '../entities/ledger_entry_entity.dart';

/// [ReconciliationItem] — Result of reconciling currency balance against ledger entries
class ReconciliationItem {
  final Currency currency;
  final int ledgerSum; // Sum of ledger entries (debts - payments)
  final int accountBalance; // Balance stored in accounts document
  final int difference; // Discrepancy (0 = exact match)

  const ReconciliationItem({
    required this.currency,
    required this.ledgerSum,
    required this.accountBalance,
    required this.difference,
  });

  bool get isMatch => difference == 0;
}

/// [ReconciliationReport] — Full reconciliation report for a retailer's account
class ReconciliationReport {
  final String retailerId;
  final String retailerName;
  final int totalEntriesCount;
  final Map<Currency, ReconciliationItem> items;

  const ReconciliationReport({
    required this.retailerId,
    required this.retailerName,
    required this.totalEntriesCount,
    required this.items,
  });

  /// Whether all currencies are 100% matched without discrepancies
  bool get isAllMatched => items.values.every((item) => item.isMatch);
}

/// Pure function to compute reconciliation without database access for unit testing (Task 5.7.1)
ReconciliationReport computeReconciliation({
  required String retailerId,
  required String retailerName,
  required List<LedgerEntryEntity> entries,
  required Map<Currency, int> accountBalances,
}) {
  final Map<Currency, int> ledgerSums = {
    Currency.yer: 0,
    Currency.sar: 0,
    Currency.usd: 0,
  };

  for (final entry in entries) {
    if (entry.type == LedgerEntryType.debt) {
      ledgerSums[entry.currency] =
          (ledgerSums[entry.currency] ?? 0) + entry.amount;
    } else if (entry.type == LedgerEntryType.payment) {
      ledgerSums[entry.currency] =
          (ledgerSums[entry.currency] ?? 0) - entry.amount;
    }
  }

  final Map<Currency, ReconciliationItem> items = {};

  for (final currency in Currency.values) {
    final lSum = ledgerSums[currency] ?? 0;
    final aBal = accountBalances[currency] ?? 0;
    final diff = aBal - lSum;

    items[currency] = ReconciliationItem(
      currency: currency,
      ledgerSum: lSum,
      accountBalance: aBal,
      difference: diff,
    );
  }

  return ReconciliationReport(
    retailerId: retailerId,
    retailerName: retailerName,
    totalEntriesCount: entries.length,
    items: items,
  );
}
