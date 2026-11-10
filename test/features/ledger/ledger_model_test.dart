import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/ledger/data/models/account_model.dart';
import 'package:vatix/features/ledger/data/models/ledger_entry_model.dart';
import 'package:vatix/features/ledger/domain/entities/account_entity.dart';
import 'package:vatix/features/ledger/domain/entities/ledger_entry_entity.dart';

Map<String, dynamic> createSampleLedgerData({
  String type = 'DEBT',
  int amount = 500000,
  String currency = 'YER',
  String? method,
  String? reference,
  String? note,
  Timestamp? timestamp,
}) {
  return {
    'wholesalerId': 'w_001',
    'retailerId': 'r_002',
    'type': type,
    'amount': amount,
    'currency': currency,
    'orderId': 'order_xyz',
    'createdBy': 'uid_admin',
    if (method != null) 'method': method,
    if (reference != null) 'reference': reference,
    if (note != null) 'note': note,
    'createdAt': timestamp ?? Timestamp.fromDate(DateTime(2026, 6, 15, 10, 30)),
  };
}

Map<String, dynamic> createSampleAccountData({
  Map<String, dynamic>? balances,
  Timestamp? timestamp,
}) {
  return {
    'wholesalerId': 'w_001',
    'retailerId': 'r_002',
    'retailerName': 'بقالة السلام',
    'balances': balances ?? {'YER': 500000, 'SAR': 15000},
    'updatedAt': timestamp ?? Timestamp.fromDate(DateTime(2026, 6, 15, 10, 30)),
  };
}

void main() {
  final fixedDate = DateTime(2026, 6, 15, 10, 30);
  final fixedTimestamp = Timestamp.fromDate(fixedDate);

  group('LedgerEntryType', () {
    test('fromString يتعرف على DEBT بحروف كبيرة', () {
      expect(LedgerEntryType.fromString('DEBT'), LedgerEntryType.debt);
    });

    test('fromString يتعرف على PAYMENT بحروف كبيرة', () {
      expect(LedgerEntryType.fromString('PAYMENT'), LedgerEntryType.payment);
    });

    test('fromString يتعرف على debt بحروف صغيرة', () {
      expect(LedgerEntryType.fromString('debt'), LedgerEntryType.debt);
    });

    test('fromString يرمي ArgumentError عند قيمة غير معروفة', () {
      expect(
        () => LedgerEntryType.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('tryFromString يرجع null لقيمة null', () {
      expect(LedgerEntryType.tryFromString(null), isNull);
    });

    test('tryFromString يرجع null لقيمة غير معروفة', () {
      expect(LedgerEntryType.tryFromString('INVALID'), isNull);
    });

    test('code صحيح لكل نوع', () {
      expect(LedgerEntryType.debt.code, 'DEBT');
      expect(LedgerEntryType.payment.code, 'PAYMENT');
    });

    test('arabicLabel غير فارغ لكل نوع', () {
      for (final t in LedgerEntryType.values) {
        expect(t.arabicLabel, isNotEmpty);
      }
    });
  });

  group('PaymentMethod', () {
    test('fromString يتعرف على CASH و TRANSFER و CHECK', () {
      expect(PaymentMethod.fromString('CASH'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('TRANSFER'), PaymentMethod.transfer);
      expect(PaymentMethod.fromString('CHECK'), PaymentMethod.check);
    });

    test('tryFromString يرجع null للقيم الخاطئة', () {
      expect(PaymentMethod.tryFromString(null), isNull);
      expect(PaymentMethod.tryFromString('UNKNOWN'), isNull);
    });
  });

  group('LedgerEntryModel', () {
    test('fromFirestoreMap يحلل قيد DEBT بـ YER بشكل صحيح', () {
      final data = createSampleLedgerData(timestamp: fixedTimestamp);
      final model = LedgerEntryModel.fromFirestoreMap('DEBT_order_xyz_YER', data);

      expect(model.id, 'DEBT_order_xyz_YER');
      expect(model.wholesalerId, 'w_001');
      expect(model.retailerId, 'r_002');
      expect(model.type, LedgerEntryType.debt);
      expect(model.amount, 500000);
      expect(model.currency, Currency.yer);
      expect(model.orderId, 'order_xyz');
      expect(model.createdBy, 'uid_admin');
      expect(model.note, isNull);
      expect(model.createdAt, fixedDate);
    });

    test('fromFirestoreMap يحلل قيد PAYMENT بـ SAR مع طريقة ومرجع وملاحظة', () {
      final data = createSampleLedgerData(
        type: 'PAYMENT',
        amount: 15000,
        currency: 'SAR',
        method: 'TRANSFER',
        reference: 'TRX-9988',
        note: 'دفعة أولى',
        timestamp: fixedTimestamp,
      );
      final model = LedgerEntryModel.fromFirestoreMap('payment_uuid_001', data);

      expect(model.type, LedgerEntryType.payment);
      expect(model.amount, 15000);
      expect(model.currency, Currency.sar);
      expect(model.method, PaymentMethod.transfer);
      expect(model.reference, 'TRX-9988');
      expect(model.note, 'دفعة أولى');
    });

    test('toFirestoreMap يولد الحقول الصحيحة بدون note', () {
      final model = LedgerEntryModel(
        id: 'DEBT_order_abc_YER',
        wholesalerId: 'w_001',
        retailerId: 'r_002',
        type: LedgerEntryType.debt,
        amount: 250000,
        currency: Currency.yer,
        orderId: 'order_abc',
        createdBy: 'uid_wholesaler',
        createdAt: fixedDate,
      );

      final map = model.toFirestoreMap();

      expect(map['wholesalerId'], 'w_001');
      expect(map['retailerId'], 'r_002');
      expect(map['type'], 'DEBT');
      expect(map['amount'], 250000);
      expect(map['currency'], 'YER');
      expect(map['orderId'], 'order_abc');
      expect(map['createdBy'], 'uid_wholesaler');
      expect(map.containsKey('note'), isFalse);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('toFirestoreMap يشمل note و method و reference عندما تكون موجودة', () {
      final model = LedgerEntryModel(
        id: 'pay_001',
        wholesalerId: 'w_001',
        retailerId: 'r_002',
        type: LedgerEntryType.payment,
        amount: 10000,
        currency: Currency.sar,
        orderId: '',
        createdBy: 'uid_wholesaler',
        method: PaymentMethod.cash,
        reference: 'REC-001',
        note: 'سداد نقدي مباشر',
        createdAt: fixedDate,
      );

      final map = model.toFirestoreMap();
      expect(map['method'], 'CASH');
      expect(map['reference'], 'REC-001');
      expect(map['note'], 'سداد نقدي مباشر');
    });

    test('round-trip: fromFirestoreMap ثم toFirestoreMap يحافظ على البيانات', () {
      final originalData = createSampleLedgerData(
        type: 'PAYMENT',
        amount: 75000,
        currency: 'USD',
        method: 'CHECK',
        reference: 'CHK-1234',
        note: 'شيك مصرفي',
        timestamp: fixedTimestamp,
      );
      final model = LedgerEntryModel.fromFirestoreMap('pay_round', originalData);
      final roundTrip = model.toFirestoreMap();

      expect(roundTrip['type'], 'PAYMENT');
      expect(roundTrip['amount'], 75000);
      expect(roundTrip['currency'], 'USD');
      expect(roundTrip['method'], 'CHECK');
      expect(roundTrip['reference'], 'CHK-1234');
      expect(roundTrip['note'], 'شيك مصرفي');
      expect(roundTrip['wholesalerId'], originalData['wholesalerId']);
    });

    test('fromFirestoreMap يتعامل مع البيانات المفقودة بقيم افتراضية', () {
      final model = LedgerEntryModel.fromFirestoreMap('empty_doc', {});

      expect(model.wholesalerId, '');
      expect(model.retailerId, '');
      expect(model.type, LedgerEntryType.debt);
      expect(model.amount, 0);
      expect(model.currency, Currency.yer);
      expect(model.note, isNull);
    });

    test('fromEntity ينشئ نموذجاً صحيحاً من entity', () {
      final entity = LedgerEntryEntity(
        id: 'e_001',
        wholesalerId: 'w_1',
        retailerId: 'r_1',
        type: LedgerEntryType.debt,
        amount: 100,
        currency: Currency.yer,
        orderId: 'o_1',
        createdBy: 'u_1',
        createdAt: DateTime(2026, 1, 1),
      );

      final model = LedgerEntryModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.amount, entity.amount);
      expect(model.type, entity.type);
    });

    test('equality تعتمد على id فقط', () {
      final a = LedgerEntryModel(
        id: 'same_id',
        wholesalerId: 'w1',
        retailerId: 'r1',
        type: LedgerEntryType.debt,
        amount: 100,
        currency: Currency.yer,
        orderId: 'o1',
        createdBy: 'u1',
        createdAt: fixedDate,
      );
      final b = LedgerEntryModel(
        id: 'same_id',
        wholesalerId: 'w2',
        retailerId: 'r2',
        type: LedgerEntryType.payment,
        amount: 999,
        currency: Currency.sar,
        orderId: 'o2',
        createdBy: 'u2',
        createdAt: fixedDate,
      );
      expect(a, equals(b));
    });
  });

  group('AccountModel', () {
    test('fromFirestoreMap يحلل الحساب مع رصيدين صحيح', () {
      final data = createSampleAccountData(timestamp: fixedTimestamp);
      final model = AccountModel.fromFirestoreMap(data);

      expect(model.wholesalerId, 'w_001');
      expect(model.retailerId, 'r_002');
      expect(model.retailerName, 'بقالة السلام');
      expect(model.balanceFor(Currency.yer), 500000);
      expect(model.balanceFor(Currency.sar), 15000);
      expect(model.balanceFor(Currency.usd), 0);
      expect(model.updatedAt, fixedDate);
    });

    test('documentId يُولَّد صحيحاً', () {
      final data = createSampleAccountData();
      final model = AccountModel.fromFirestoreMap(data);
      expect(model.documentId, 'w_001_r_002');
    });

    test('hasDebt صحيح عند وجود رصيد موجب', () {
      final data = createSampleAccountData(balances: {'YER': 1});
      expect(AccountModel.fromFirestoreMap(data).hasDebt, isTrue);
    });

    test('isSettled صحيح عند رصيد صفري لجميع العملات', () {
      final data = createSampleAccountData(balances: {'YER': 0, 'SAR': 0});
      expect(AccountModel.fromFirestoreMap(data).isSettled, isTrue);
    });

    test('fromFirestoreMap يتجاهل عملة غير معروفة بدون استثناء', () {
      final data = createSampleAccountData(balances: {'YER': 100, 'XXX': 999});
      final model = AccountModel.fromFirestoreMap(data);
      expect(model.balanceFor(Currency.yer), 100);
      expect(model.balances.length, 1);
    });

    test('toFirestoreMap يولد البيانات الصحيحة', () {
      final model = AccountModel(
        wholesalerId: 'w_001',
        retailerId: 'r_002',
        retailerName: 'بقالة السلام',
        balances: const {Currency.yer: 300000, Currency.sar: 5000},
        updatedAt: fixedDate,
      );

      final map = model.toFirestoreMap();
      expect(map['wholesalerId'], 'w_001');
      expect(map['retailerId'], 'r_002');
      expect(map['retailerName'], 'بقالة السلام');
      expect((map['balances'] as Map)['YER'], 300000);
      expect((map['balances'] as Map)['SAR'], 5000);
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('round-trip: fromFirestoreMap ثم toFirestoreMap يحافظ على البيانات', () {
      final original = createSampleAccountData(
        balances: {'YER': 750000, 'USD': 2500},
        timestamp: fixedTimestamp,
      );
      final model = AccountModel.fromFirestoreMap(original);
      final map = model.toFirestoreMap();

      expect((map['balances'] as Map)['YER'], 750000);
      expect((map['balances'] as Map)['USD'], 2500);
      expect(map['retailerName'], original['retailerName']);
    });

    test('fromFirestoreMap يتعامل مع البيانات الفارغة بقيم افتراضية', () {
      final model = AccountModel.fromFirestoreMap({});

      expect(model.wholesalerId, '');
      expect(model.retailerId, '');
      expect(model.retailerName, '');
      expect(model.balances, isEmpty);
    });

    test('fromEntity ينشئ نموذجاً صحيحاً من entity', () {
      final entity = AccountEntity(
        wholesalerId: 'w1',
        retailerId: 'r1',
        retailerName: 'بقالة',
        balances: const {Currency.yer: 100},
        updatedAt: DateTime(2026, 1, 1),
      );

      final model = AccountModel.fromEntity(entity);
      expect(model.wholesalerId, entity.wholesalerId);
      expect(model.balanceFor(Currency.yer), 100);
    });

    test('equality تعتمد على wholesalerId و retailerId', () {
      final a = AccountModel(
        wholesalerId: 'w1',
        retailerId: 'r1',
        retailerName: 'بقالة أ',
        balances: const {Currency.yer: 100},
        updatedAt: DateTime(2026, 1, 1),
      );
      final b = AccountModel(
        wholesalerId: 'w1',
        retailerId: 'r1',
        retailerName: 'بقالة ب',
        balances: const {Currency.sar: 999},
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(a, equals(b));
    });
  });
}
