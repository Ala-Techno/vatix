import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/utils/currency.dart';
import '../../domain/entities/order_entity.dart';
import 'order_item_model.dart';

/// [OrderModel] — Purchase order model connected to Firestore
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

  /// Converts from Firestore document [DocumentSnapshot]
  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // 1. Convert order items
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => OrderItemModel.fromFirestoreMap(e as Map<String, dynamic>))
        .toList();

    // 2. Convert totals
    final rawTotals = data['totals'] as Map<String, dynamic>? ?? {};
    final totals = <Currency, int>{};
    for (final entry in rawTotals.entries) {
      try {
        final currency = Currency.fromString(entry.key);
        totals[currency] = (entry.value as num).toInt();
      } catch (_) {
        // Ignore any invalid currency if encountered
      }
    }

    // 3. Timestamps
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

  /// Converts to Map for storing in Firestore
  Map<String, dynamic> toFirestoreMap({bool isCreate = false}) {
    // Convert totals to Map<String, int> keyed by currency codes
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
      'assignedDistributorId': null, // Deferred to V2
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    };
  }
}

