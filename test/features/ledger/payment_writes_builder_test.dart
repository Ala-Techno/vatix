import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/ledger/domain/entities/ledger_entry_entity.dart';
import 'package:vatix/features/ledger/domain/usecases/payment_writes_builder.dart';

void main() {
  group('PaymentWritesBuilder Tests (Task 5.4.4)', () {
    test('buildPaymentWrites creates correct plan with valid inputs', () {
      final plan = buildPaymentWrites(
        wholesalerId: 'who_123',
        retailerId: 'ret_456',
        retailerName: 'سوبرماركت البركة',
        amount: 50000,
        currency: Currency.yer,
        method: PaymentMethod.cash,
        reference: 'REC-001',
        note: 'سداد نقدي مباشر في المحل',
        createdBy: 'user_admin',
        ledgerDocId: 'ledger_doc_999',
      );

      expect(plan.ledgerDocId, 'ledger_doc_999');
      expect(plan.accountDocId, 'who_123_ret_456');
      expect(plan.wholesalerId, 'who_123');
      expect(plan.retailerId, 'ret_456');
      expect(plan.retailerName, 'سوبرماركت البركة');
      expect(plan.amount, 50000);
      expect(plan.currency, Currency.yer);
      expect(plan.method, PaymentMethod.cash);
      expect(plan.reference, 'REC-001');
      expect(plan.note, 'سداد نقدي مباشر في المحل');
      expect(plan.createdBy, 'user_admin');
      expect(plan.balanceDecrement, -50000);

      final ledgerData = plan.toLedgerData();
      expect(ledgerData['wholesalerId'], 'who_123');
      expect(ledgerData['retailerId'], 'ret_456');
      expect(ledgerData['type'], 'PAYMENT');
      expect(ledgerData['amount'], 50000);
      expect(ledgerData['currency'], 'YER');
      expect(ledgerData['method'], 'CASH');
      expect(ledgerData['reference'], 'REC-001');
      expect(ledgerData['note'], 'سداد نقدي مباشر في المحل');
      expect(ledgerData['createdBy'], 'user_admin');
      expect(ledgerData['orderId'], '');
    });

    test('buildPaymentWrites strips whitespace and omits empty optional fields', () {
      final plan = buildPaymentWrites(
        wholesalerId: '  who_123  ',
        retailerId: '  ret_456  ',
        retailerName: '  سوبرماركت  ',
        amount: 2500,
        currency: Currency.sar,
        method: PaymentMethod.transfer,
        reference: '   ',
        note: null,
        createdBy: '  user_admin  ',
        ledgerDocId: 'doc_1',
      );

      expect(plan.wholesalerId, 'who_123');
      expect(plan.retailerId, 'ret_456');
      expect(plan.accountDocId, 'who_123_ret_456');
      expect(plan.reference, isNull);
      expect(plan.note, isNull);

      final ledgerData = plan.toLedgerData();
      expect(ledgerData.containsKey('reference'), isFalse);
      expect(ledgerData.containsKey('note'), isFalse);
    });

    test('buildPaymentWrites throws ArgumentError for amount <= 0', () {
      expect(
        () => buildPaymentWrites(
          wholesalerId: 'w',
          retailerId: 'r',
          retailerName: 'n',
          amount: 0,
          currency: Currency.yer,
          method: PaymentMethod.cash,
          createdBy: 'u',
          ledgerDocId: 'd',
        ),
        throwsArgumentError,
      );

      expect(
        () => buildPaymentWrites(
          wholesalerId: 'w',
          retailerId: 'r',
          retailerName: 'n',
          amount: -500,
          currency: Currency.yer,
          method: PaymentMethod.cash,
          createdBy: 'u',
          ledgerDocId: 'd',
        ),
        throwsArgumentError,
      );
    });

    test('buildPaymentWrites throws ArgumentError for empty required strings', () {
      expect(
        () => buildPaymentWrites(
          wholesalerId: '',
          retailerId: 'r',
          retailerName: 'n',
          amount: 100,
          currency: Currency.yer,
          method: PaymentMethod.cash,
          createdBy: 'u',
          ledgerDocId: 'd',
        ),
        throwsArgumentError,
      );

      expect(
        () => buildPaymentWrites(
          wholesalerId: 'w',
          retailerId: '   ',
          retailerName: 'n',
          amount: 100,
          currency: Currency.yer,
          method: PaymentMethod.cash,
          createdBy: 'u',
          ledgerDocId: 'd',
        ),
        throwsArgumentError,
      );

      expect(
        () => buildPaymentWrites(
          wholesalerId: 'w',
          retailerId: 'r',
          retailerName: 'n',
          amount: 100,
          currency: Currency.yer,
          method: PaymentMethod.cash,
          createdBy: '',
          ledgerDocId: 'd',
        ),
        throwsArgumentError,
      );
    });
  });
}

