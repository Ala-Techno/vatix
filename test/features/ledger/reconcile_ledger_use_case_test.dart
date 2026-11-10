import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/ledger/domain/entities/ledger_entry_entity.dart';
import 'package:vatix/features/ledger/domain/usecases/reconcile_ledger_use_case.dart';

void main() {
  group('Reconciliation Tool Tests (Task 5.7)', () {
    final now = DateTime(2026, 6, 15);

    LedgerEntryEntity makeEntry({
      required String id,
      required LedgerEntryType type,
      required int amount,
      required Currency currency,
    }) {
      return LedgerEntryEntity(
        id: id,
        wholesalerId: 'w_01',
        retailerId: 'r_01',
        type: type,
        amount: amount,
        currency: currency,
        orderId: type == LedgerEntryType.debt ? 'o_1' : '',
        createdBy: 'u_1',
        createdAt: now,
      );
    }

    test('All matched when ledger sum equals account balances', () {
      final entries = [
        makeEntry(id: 'd1', type: LedgerEntryType.debt, amount: 100000, currency: Currency.yer),
        makeEntry(id: 'p1', type: LedgerEntryType.payment, amount: 30000, currency: Currency.yer),
        makeEntry(id: 'd2', type: LedgerEntryType.debt, amount: 5000, currency: Currency.sar),
        makeEntry(id: 'p2', type: LedgerEntryType.payment, amount: 2000, currency: Currency.sar),
      ];

      // YER balance = 100,000 - 30,000 = 70,000
      // SAR balance = 5,000 - 2,000 = 3,000
      // USD balance = 0
      final accountBalances = {
        Currency.yer: 70000,
        Currency.sar: 3000,
        Currency.usd: 0,
      };

      final report = computeReconciliation(
        retailerId: 'r_01',
        retailerName: 'بقالة الأمل',
        entries: entries,
        accountBalances: accountBalances,
      );

      expect(report.totalEntriesCount, 4);
      expect(report.isAllMatched, isTrue);

      final yerItem = report.items[Currency.yer]!;
      expect(yerItem.ledgerSum, 70000);
      expect(yerItem.accountBalance, 70000);
      expect(yerItem.difference, 0);
      expect(yerItem.isMatch, isTrue);

      final sarItem = report.items[Currency.sar]!;
      expect(sarItem.ledgerSum, 3000);
      expect(sarItem.accountBalance, 3000);
      expect(sarItem.difference, 0);
      expect(sarItem.isMatch, isTrue);

      final usdItem = report.items[Currency.usd]!;
      expect(usdItem.difference, 0);
      expect(usdItem.isMatch, isTrue);
    });

    test('Detects mismatch and calculates differences accurately', () {
      final entries = [
        makeEntry(id: 'd1', type: LedgerEntryType.debt, amount: 50000, currency: Currency.yer),
        makeEntry(id: 'p1', type: LedgerEntryType.payment, amount: 10000, currency: Currency.yer),
      ];

      // Ledger net = 40,000, but account has 50,000 (diff = +10,000)
      final accountBalances = {
        Currency.yer: 50000,
        Currency.sar: 0,
        Currency.usd: 0,
      };

      final report = computeReconciliation(
        retailerId: 'r_01',
        retailerName: 'بقالة الأمل',
        entries: entries,
        accountBalances: accountBalances,
      );

      expect(report.isAllMatched, isFalse);

      final yerItem = report.items[Currency.yer]!;
      expect(yerItem.ledgerSum, 40000);
      expect(yerItem.accountBalance, 50000);
      expect(yerItem.difference, 10000);
      expect(yerItem.isMatch, isFalse);
    });

    test('Handles empty entries list cleanly', () {
      final report = computeReconciliation(
        retailerId: 'r_01',
        retailerName: 'بقالة الأمل',
        entries: [],
        accountBalances: {
          Currency.yer: 0,
          Currency.sar: 0,
          Currency.usd: 0,
        },
      );

      expect(report.totalEntriesCount, 0);
      expect(report.isAllMatched, isTrue);
    });
  });
}

