import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/orders/domain/entities/order_entity.dart';
import 'package:vatix/features/orders/domain/entities/order_item_entity.dart';
import 'package:vatix/features/orders/domain/usecases/approval_writes_builder.dart';

void main() {
  group('ApprovalWritesBuilder Tests (Task 4.5.1 & 4.5.5)', () {
    final now = DateTime.now();

    final testItem1 = OrderItemEntity(
      productId: 'p1',
      name: 'سكر أبيض 50كجم',
      unit: 'كيس',
      unitPrice: 20000,
      currency: Currency.yer,
      quantity: 2,
      lineTotal: 40000,
    );

    final testItem2 = OrderItemEntity(
      productId: 'p2',
      name: 'أرز بسمتي 40كجم',
      unit: 'شوال',
      unitPrice: 15000, // 150.00 SAR
      currency: Currency.sar,
      quantity: 1,
      lineTotal: 15000,
    );

    test('1. اعتماد آجل بعملة واحدة ينشئ قيد دين واحد وتحديث حساب increment واحد', () {
      final order = OrderEntity(
        id: 'ord_123',
        retailerId: 'ret_001',
        wholesalerId: 'who_999',
        retailerName: 'بقالة الأمل',
        wholesalerName: 'شركة الوفرة',
        items: [testItem1],
        totals: {Currency.yer: 40000},
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final plan = buildApprovalWrites(
        order: order,
        paymentType: PaymentType.credit,
        currentUid: 'who_999',
      );

      expect(plan.orderId, 'ord_123');
      expect(plan.paymentType, PaymentType.credit);

      // 1 قيد DEBT فقط
      expect(plan.ledgerEntries.length, 1);
      final debtEntry = plan.ledgerEntries.first;
      expect(debtEntry.docId, 'debt_ord_123_YER');
      expect(debtEntry.type, 'DEBT');
      expect(debtEntry.amount, 40000);
      expect(debtEntry.currency, 'YER');
      expect(debtEntry.wholesalerId, 'who_999');
      expect(debtEntry.retailerId, 'ret_001');

      // تحديث الحساب
      expect(plan.accountUpdate, isNotNull);
      expect(plan.accountUpdate!.accountDocId, 'who_999_ret_001');
      expect(plan.accountUpdate!.increments['YER'], 40000);
    });

    test('2. اعتماد آجل بعملتين ينشئ قيدي دين وتحديث حساب بالزيادة للعملتين', () {
      final order = OrderEntity(
        id: 'ord_multi',
        retailerId: 'ret_002',
        wholesalerId: 'who_999',
        retailerName: 'تموينات النور',
        wholesalerName: 'شركة الوفرة',
        items: [testItem1, testItem2],
        totals: {
          Currency.yer: 40000,
          Currency.sar: 15000,
        },
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final plan = buildApprovalWrites(
        order: order,
        paymentType: PaymentType.credit,
        currentUid: 'who_999',
      );

      expect(plan.ledgerEntries.length, 2);
      expect(
        plan.ledgerEntries.any((e) => e.docId == 'debt_ord_multi_YER' && e.amount == 40000),
        isTrue,
      );
      expect(
        plan.ledgerEntries.any((e) => e.docId == 'debt_ord_multi_SAR' && e.amount == 15000),
        isTrue,
      );

      expect(plan.accountUpdate, isNotNull);
      expect(plan.accountUpdate!.increments['YER'], 40000);
      expect(plan.accountUpdate!.increments['SAR'], 15000);
    });

    test('3. اعتماد نقد بعملتين ينشئ قيدي دين وقيدي سداد ولا ينشئ أي increment للحساب', () {
      final order = OrderEntity(
        id: 'ord_cash',
        retailerId: 'ret_003',
        wholesalerId: 'who_999',
        retailerName: 'سوبرماركت التوفيق',
        wholesalerName: 'شركة الوفرة',
        items: [testItem1, testItem2],
        totals: {
          Currency.yer: 40000,
          Currency.sar: 15000,
        },
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final plan = buildApprovalWrites(
        order: order,
        paymentType: PaymentType.cash,
        currentUid: 'who_999',
      );

      // ينشئ 4 قيود: 2 دين + 2 سداد
      expect(plan.ledgerEntries.length, 4);

      final debts = plan.ledgerEntries.where((e) => e.type == 'DEBT').toList();
      final payments = plan.ledgerEntries.where((e) => e.type == 'PAYMENT').toList();

      expect(debts.length, 2);
      expect(payments.length, 2);

      expect(debts.any((e) => e.docId == 'debt_ord_cash_YER' && e.amount == 40000), isTrue);
      expect(debts.any((e) => e.docId == 'debt_ord_cash_SAR' && e.amount == 15000), isTrue);

      expect(payments.any((e) => e.docId == 'pay_ord_cash_YER' && e.amount == 40000), isTrue);
      expect(payments.any((e) => e.docId == 'pay_ord_cash_SAR' && e.amount == 15000), isTrue);

      // في النقد: لا يتغير رصيد التاجر (accountUpdate == null)
      expect(plan.accountUpdate, isNull);
    });
  });
}
