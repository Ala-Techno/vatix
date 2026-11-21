import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/approval_writes_builder.dart';
import '../models/order_model.dart';

/// Orders page data result from Firestore
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

/// [OrdersRemoteDataSource] — Remote data source contract for Firestore
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

  /// Real-time stream of pending orders for wholesaler (max 50 for Dashboard and Badge)
  Stream<List<OrderModel>> watchPendingOrdersForWholesaler({
    required String wholesalerId,
    int limit = 50,
  });

  /// Real-time stream of wholesaler orders filtered by status
  Stream<List<OrderModel>> watchWholesalerOrders({
    required String wholesalerId,
    String? status,
    int limit = 50,
  });

  /// Fetch a page of incoming wholesaler orders with optional status filter
  Future<OrdersPageData> getWholesalerOrdersPage({
    required String wholesalerId,
    String? status,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  });

  /// Atomically approve purchase order, write ledger entries, and update accounts (Task 4.5)
  Future<void> approveOrder({
    required OrderModel order,
    required PaymentType paymentType,
    required String currentUid,
  });

  /// Reject purchase order with a mandatory reason (Task 4.6.1)
  Future<void> rejectOrder({
    required String orderId,
    required String rejectionReason,
  });

  /// Confirm purchase order delivery (Task 4.6.2)
  Future<void> deliverOrder({
    required String orderId,
  });
}

/// [OrdersRemoteDataSourceImpl] — Orders remote data source implementation using Cloud Firestore
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
      hasPendingWrites: true, // E3: Pending synchronization flag
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );

    // Save order to Firestore and immediately synchronize cache
    await docRef.set(newOrder.toFirestoreMap(isCreate: true));

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
        // includeMetadataChanges: true ensures seeing immediate updates
        // from either the server or local cache (pending writes)
        .snapshots(includeMetadataChanges: true)
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
  Stream<List<OrderModel>> watchWholesalerOrders({
    required String wholesalerId,
    String? status,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query =
        _ordersRef.where('wholesalerId', isEqualTo: wholesalerId);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
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
    // 1. Use pure function to build atomic write plan
    final plan = buildApprovalWrites(
      order: order,
      paymentType: paymentType,
      currentUid: currentUid,
    );

    final batch = _firestore.batch();

    // A) Update order document
    final orderDoc = _ordersRef.doc(order.id);
    batch.update(orderDoc, {
      'status': OrderStatus.approved.name,
      'paymentType': paymentType.code,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // B) Add deterministic ID ledger entries
    final ledgerRef = _firestore.collection('ledger');
    for (final entry in plan.ledgerEntries) {
      final doc = ledgerRef.doc(entry.docId);
      final data = entry.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      batch.set(doc, data);
    }

    // C) Update cumulative balances in accounts if payment is on credit (using Nested Map)
    if (plan.accountUpdate != null) {
      final accountPlan = plan.accountUpdate!;
      final accountDoc =
          _firestore.collection('accounts').doc(accountPlan.accountDocId);

      // Build nested map for balances with FieldValue.increment per currency
      final Map<String, dynamic> balancesMap = {};
      for (final e in accountPlan.increments.entries) {
        balancesMap[e.key] = FieldValue.increment(e.value);
      }

      batch.set(
        accountDoc,
        {
          'wholesalerId': accountPlan.wholesalerId,
          'retailerId': accountPlan.retailerId,
          'retailerName': accountPlan.retailerName,
          'updatedAt': FieldValue.serverTimestamp(),
          'balances': balancesMap, // Exclusively saved as Nested Map
        },
        SetOptions(merge: true),
      );
    }

    // D) Pre-check stock sufficiency for each item before deduction
    final productsRef = _firestore.collection('products');
    for (final item in order.items) {
      final pid = item.productId.trim();
      if (pid.isEmpty) continue;

      final productDoc = await productsRef.doc(pid).get();
      if (productDoc.exists) {
        final data = productDoc.data() ?? {};
        final currentStock = (data['stockQuantity'] as num?)?.toInt();
        // If stock is tracked and requested quantity exceeds available => prevent approval
        if (currentStock != null && currentStock < item.quantity) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'out-of-stock',
            message:
                'تعذّر اعتماد الطلب: نفذت كمية المخزون للصنف "${item.name}". المتوفر حالياً: $currentStock، والمطلوب: ${item.quantity}.',
          );
        }
      }

      // Atomically deduct requested quantity from stock
      batch.update(productsRef.doc(pid), {
        'stockQuantity': FieldValue.increment(-item.quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // E3: Fire-and-forget to prevent UI freeze on connection drop
    unawaited(batch.commit());

    // E) After commit, check each product: if stock reaches 0 or below -> disable it
    // This is outside the batch because FieldValue.increment cannot be read before commit
    _disableOutOfStockProducts(
      items: order.items,
      productsRef: productsRef,
    );
  }

  /// Disables out-of-stock products after order approval
  /// Runs asynchronously (fire-and-forget) to prevent UI freeze
  void _disableOutOfStockProducts({
    required List<dynamic> items,
    required CollectionReference<Map<String, dynamic>> productsRef,
  }) {
    unawaited(_doDisableOutOfStock(items: items, productsRef: productsRef));
  }

  Future<void> _doDisableOutOfStock({
    required List<dynamic> items,
    required CollectionReference<Map<String, dynamic>> productsRef,
  }) async {
    for (final item in items) {
      final pid = (item.productId as String).trim();
      if (pid.isEmpty) continue;

      try {
        // Read current stock after deduction
        final snap = await productsRef.doc(pid).get();
        if (!snap.exists) continue;

        final data = snap.data() ?? {};
        final stock = (data['stockQuantity'] as num?)?.toInt();

        // If stock is tracked (not null) and reached 0 or less -> disable
        if (stock != null && stock <= 0) {
          await productsRef.doc(pid).update({
            'isAvailable': false,
            'stockQuantity': 0, // Do not leave negative value
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {
        // Ignore individual errors so remaining operations continue
      }
    }
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

