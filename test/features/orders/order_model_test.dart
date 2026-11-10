import 'package:flutter_test/flutter_test.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/features/orders/data/models/order_item_model.dart';
import 'package:vatix/features/orders/data/models/order_model.dart';
import 'package:vatix/features/orders/domain/entities/order_entity.dart';

void main() {
  group('OrderModel & OrderItemModel Tests', () {
    final now = DateTime(2026, 3, 15, 12, 0);

    const testItem = OrderItemModel(
      productId: 'p_101',
      name: 'حليب ممتاز 390 جم',
      unit: 'كرتون',
      unitPrice: 18500,
      currency: Currency.yer,
      quantity: 2,
      lineTotal: 37000,
      sku: 'MLK-01',
    );

    final testOrder = OrderModel(
      id: 'order_abc123456',
      retailerId: 'ret_1',
      wholesalerId: 'who_1',
      retailerName: 'بقالة الأمانة',
      wholesalerName: 'شركة النور للمواد الغذائية',
      items: const [testItem],
      totals: const {Currency.yer: 37000},
      status: OrderStatus.pending,
      paymentType: PaymentType.credit,
      note: 'يرجى التوصيل قبل الظهر',
      hasPendingWrites: false,
      createdAt: now,
      updatedAt: now,
    );

    test('shortId formats correctly to 6 uppercase chars prefixed with #', () {
      expect(testOrder.shortId, '#ORDER_');
    });

    test('formattedTotalsSummary formats multi-currency totals correctly', () {
      expect(testOrder.formattedTotalsSummary, '37,000 ر.ي');

      final multiOrder = testOrder.copyWith(
        totals: {
          Currency.yer: 37000,
          Currency.sar: 5200,
        },
      );
      expect(multiOrder.formattedTotalsSummary, contains('37,000 ر.ي'));
      expect(multiOrder.formattedTotalsSummary, contains('52.00 ر.س'));
    });

    test('canCancel is true only when status is pending', () {
      expect(testOrder.canCancel, isTrue);

      final approvedOrder = testOrder.copyWith(status: OrderStatus.approved);
      expect(approvedOrder.canCancel, isFalse);

      final deliveredOrder = testOrder.copyWith(status: OrderStatus.delivered);
      expect(deliveredOrder.canCancel, isFalse);
    });

    test('toFirestoreMap generates correct fields for Firestore', () {
      final map = testOrder.toFirestoreMap(isCreate: true);

      expect(map['retailerId'], 'ret_1');
      expect(map['wholesalerId'], 'who_1');
      expect(map['retailerName'], 'بقالة الأمانة');
      expect(map['wholesalerName'], 'شركة النور للمواد الغذائية');
      expect(map['status'], 'pending');
      expect(map['paymentType'], 'credit');
      expect(map['note'], 'يرجى التوصيل قبل الظهر');
      expect(map['assignedDistributorId'], isNull);

      final totals = map['totals'] as Map<String, dynamic>;
      expect(totals['YER'], 37000);

      final items = map['items'] as List<dynamic>;
      expect(items.length, 1);
      final itemMap = items.first as Map<String, dynamic>;
      expect(itemMap['productId'], 'p_101');
      expect(itemMap['unitPrice'], 18500);
      expect(itemMap['currency'], 'YER');
      expect(itemMap['quantity'], 2);
      expect(itemMap['lineTotal'], 37000);
    });

    test('OrderItemModel.fromFirestoreMap parses map correctly', () {
      final map = {
        'productId': 'p_102',
        'name': 'زيت دوار الشمس',
        'unit': 'كرتون',
        'unitPrice': 5200,
        'currency': 'SAR',
        'quantity': 3,
        'lineTotal': 15600,
      };

      final model = OrderItemModel.fromFirestoreMap(map);

      expect(model.productId, 'p_102');
      expect(model.name, 'زيت دوار الشمس');
      expect(model.unitPrice, 5200);
      expect(model.currency, Currency.sar);
      expect(model.quantity, 3);
      expect(model.lineTotal, 15600);
      expect(model.formattedUnitPrice, contains('52.00'));
      expect(model.formattedLineTotal, contains('156.00'));
    });
  });
}
