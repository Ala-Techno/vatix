import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/order_entity.dart';
import 'order_item_model.dart';

/// [OrderModel] — تمثيل أمر الشراء المتصل بـ Firestore
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.retailerId,
    required super.wholesalerId,
    required super.retailerName,
    required super.wholesalerName,
    required super.items,
    required super.totals,
    required super.status,
    super.paymentType,
    super.note,
    super.rejectionReason,
    super.assignedDistributorId,
    super.hasPendingWrites,
    required super.createdAt,
    required super.updatedAt,
    super.approvedAt,
    super.deliveredAt,
  });

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      retailerId: entity.retailerId,
      wholesalerId: entity.wholesalerId,
      retailerName: entity.retailerName,
      wholesalerName: entity.wholesalerName,
      items: entity.items,
      totals: entity.totals,
      status: entity.status,
      paymentType: entity.paymentType,
      note: entity.note,
      rejectionReason: entity.rejectionReason,
      assignedDistributorId: entity.assignedDistributorId,
      hasPendingWrites: entity.hasPendingWrites,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      approvedAt: entity.approvedAt,
      deliveredAt: entity.deliveredAt,
    );
  }

  /// تحويل من مستند Firestore [DocumentSnapshot]
  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // 1. تحويل عناصر الطلب items
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => OrderItemModel.fromFirestoreMap(e as Map<String, dynamic>))
        .toList();

    // 2. تحويل الإجماليات totals
    final rawTotals = data['totals'] as Map<String, dynamic>? ?? {};
    final totals = <Currency, int>{};
    for (final entry in rawTotals.entries) {
      try {
        final currency = Currency.fromString(entry.key);
        totals[currency] = (entry.value as num).toInt();
      } catch (_) {
        // تجاهل أي عملة غير صالحة إن وجدت
      }
    }

    // 3. التواريخ Timestamps
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    return OrderModel(
      id: doc.id,
      retailerId: data['retailerId'] as String? ?? '',
      wholesalerId: data['wholesalerId'] as String? ?? '',
      retailerName: data['retailerName'] as String? ?? '',
      wholesalerName: data['wholesalerName'] as String? ?? '',
      items: items,
      totals: totals,
      status: OrderStatus.fromString(data['status'] as String?),
      paymentType: PaymentType.fromString(data['paymentType'] as String?),
      note: data['note'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      assignedDistributorId: data['assignedDistributorId'] as String?,
      hasPendingWrites: doc.metadata.hasPendingWrites,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      approvedAt: parseNullableDate(data['approvedAt']),
      deliveredAt: parseNullableDate(data['deliveredAt']),
    );
  }

  /// تحويل إلى خريطة Map لتخزينها في Firestore
  Map<String, dynamic> toFirestoreMap({bool isCreate = false}) {
    // تحويل totals إلى Map<String, int> بمفاتيح رموز العملات
    final totalsMap = <String, int>{};
    for (final entry in totals.entries) {
      totalsMap[entry.key.code] = entry.value;
    }

    final itemsMap = items.map((item) {
      if (item is OrderItemModel) {
        return item.toFirestoreMap();
      }
      return OrderItemModel.fromEntity(item).toFirestoreMap();
    }).toList();

    return {
      'retailerId': retailerId,
      'wholesalerId': wholesalerId,
      'retailerName': retailerName.trim(),
      'wholesalerName': wholesalerName.trim(),
      'items': itemsMap,
      'totals': totalsMap,
      'status': status.name,
      if (paymentType != null) 'paymentType': paymentType!.code,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty)
        'rejectionReason': rejectionReason!.trim(),
      'assignedDistributorId': null, // مؤجل للنسخة V2
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    };
  }
}

