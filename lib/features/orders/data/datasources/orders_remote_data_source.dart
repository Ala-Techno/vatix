import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/approval_writes_builder.dart';
import '../models/order_model.dart';

/// نتيجة صفحة بيانات الطلبات من Firestore
class OrdersPageData {
  final List<OrderModel> orders;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const OrdersPageData({
    required this.orders,
    this.lastDocument,
    required this.hasMore,
  });
}

/// [OrdersRemoteDataSource] — عقد مصدر البيانات عن بُعد لـ Firestore
abstract class OrdersRemoteDataSource {
  Future<OrderModel> placeOrder({required OrderModel order});

  Stream<List<OrderModel>> watchMyOrders({
    required String retailerId,
    int limit = 20,
  });

  Future<OrdersPageData> getMyOrdersPage({
    required String retailerId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  });

  Stream<OrderModel?> watchOrder({required String orderId});

  Future<void> cancelOrder({required String orderId});

  /// استماع لحظي للطلبات المعلقة للمورد (حد أقصى 50 للـ Dashboard والـ Badge)
  Stream<List<OrderModel>> watchPendingOrdersForWholesaler({
    required String wholesalerId,
    int limit = 50,
  });

  /// جلب صفحة من الطلبات الواردة للمورد مع إمكانية الفلترة بالحالة
  Future<OrdersPageData> getWholesalerOrdersPage({
    required String wholesalerId,
    String? status,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  });

  /// اعتماد أمر الشراء ذرياً مع كتابة قيود الدفتر وتحديث الحسابات (Task 4.5)
  Future<void> approveOrder({
    required OrderModel order,
    required PaymentType paymentType,
    required String currentUid,
  });

  /// رفض أمر الشراء مع سبب إلزامي (Task 4.6.1)
  Future<void> rejectOrder({
    required String orderId,
    required String rejectionReason,
  });

  /// تأكيد تسليم أمر الشراء (Task 4.6.2)
  Future<void> deliverOrder({
    required String orderId,
  });
}

/// [OrdersRemoteDataSourceImpl] — تنفيذ مصدر بيانات الطلبات بـ Cloud Firestore
class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrdersRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  @override
  Future<OrderModel> placeOrder({required OrderModel order}) async {
    final docRef = _ordersRef.doc();
    final newOrder = OrderModel(
      id: docRef.id,
      retailerId: order.retailerId,
      wholesalerId: order.wholesalerId,
      retailerName: order.retailerName,
      wholesalerName: order.wholesalerName,
      items: order.items,
      totals: order.totals,
      status: order.status,
      paymentType: order.paymentType,
      note: order.note,
      rejectionReason: order.rejectionReason,
      assignedDistributorId: null,
      hasPendingWrites: true, // E3: مؤشر بانتظار المزامنة
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );

    // E3: Fire-and-forget — Firestore SDK يحفظ محلياً فوراً ويزامن عند الاتصال
    // لا ننتظر تأكيد الخادم حتى لا يتجمد الزر. unawaited يمنع تحذير Dart.
    unawaited(docRef.set(newOrder.toFirestoreMap(isCreate: true)));

    return newOrder;
  }

  @override
  Stream<List<OrderModel>> watchMyOrders({
    required String retailerId,
    int limit = 20,
  }) {
    return _ordersRef
        .where('retailerId', isEqualTo: retailerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true) // للاطلاع على hasPendingWrites
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<OrdersPageData> getMyOrdersPage({
    required String retailerId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _ordersRef
        .where('retailerId', isEqualTo: retailerId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final snapshot = await query.get();

    final orders =
        snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return OrdersPageData(
      orders: orders,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  @override
  Stream<OrderModel?> watchOrder({required String orderId}) {
    return _ordersRef
        .doc(orderId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    });
  }

  @override
  Future<void> cancelOrder({required String orderId}) async {
    await _ordersRef.doc(orderId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<OrderModel>> watchPendingOrdersForWholesaler({
    required String wholesalerId,
    int limit = 50,
  }) {
    return _ordersRef
        .where('wholesalerId', isEqualTo: wholesalerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<OrdersPageData> getWholesalerOrdersPage({
    required String wholesalerId,
    String? status,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _ordersRef
        .where('wholesalerId', isEqualTo: wholesalerId);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final snapshot = await query.get();

    final orders =
        snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return OrdersPageData(
      orders: orders,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  @override
  Future<void> approveOrder({
    required OrderModel order,
    required PaymentType paymentType,
    required String currentUid,
  }) async {
    // 1. استخدام الدالة النقية لبناء خطة الكتابة الذرية
    final plan = buildApprovalWrites(
      order: order,
      paymentType: paymentType,
      currentUid: currentUid,
    );

    final batch = _firestore.batch();

    // أ) تحديث مستند الطلب
    final orderDoc = _ordersRef.doc(order.id);
    batch.update(orderDoc, {
      'status': OrderStatus.approved.name,
      'paymentType': paymentType.code,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ب) إضافة قيود الدفتر الحتمية المعرف
    final ledgerRef = _firestore.collection('ledger');
    for (final entry in plan.ledgerEntries) {
      final doc = ledgerRef.doc(entry.docId);
      final data = entry.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      batch.set(doc, data);
    }

    // ج) تحديث الأرصدة التراكمية في accounts إذا كان الدفع آجل
    if (plan.accountUpdate != null) {
      final accountPlan = plan.accountUpdate!;
      final accountDoc =
          _firestore.collection('accounts').doc(accountPlan.accountDocId);

      final balanceIncrements = <String, dynamic>{};
      for (final e in accountPlan.increments.entries) {
        balanceIncrements['balances.${e.key}'] = FieldValue.increment(e.value);
      }

      batch.set(
        accountDoc,
        {
          'wholesalerId': accountPlan.wholesalerId,
          'retailerId': accountPlan.retailerId,
          'retailerName': accountPlan.retailerName,
          'updatedAt': FieldValue.serverTimestamp(),
          ...balanceIncrements,
        },
        SetOptions(merge: true),
      );
    }

    // E3: Fire-and-forget لضمان عدم تجميد الواجهة عند انقطاع الاتصال
    unawaited(batch.commit());
  }

  @override
  Future<void> rejectOrder({
    required String orderId,
    required String rejectionReason,
  }) async {
    final future = _ordersRef.doc(orderId).update({
      'status': OrderStatus.rejected.name,
      'rejectionReason': rejectionReason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    unawaited(future);
  }

  @override
  Future<void> deliverOrder({
    required String orderId,
  }) async {
    final future = _ordersRef.doc(orderId).update({
      'status': OrderStatus.delivered.name,
      'deliveredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    unawaited(future);
  }
}

