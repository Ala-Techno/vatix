import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_data_source.dart';
import '../models/order_model.dart';

/// [OrdersRepositoryImpl] — تنفيذ مستودع الطلبات مع إدارة الأخطاء وتحويل النماذج
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remoteDataSource;

  OrdersRepositoryImpl({required OrdersRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ApiResult<OrderEntity>> placeOrder({
    required OrderEntity order,
  }) async {
    try {
      final model = order is OrderModel ? order : OrderModel.fromEntity(order);
      final created = await _remoteDataSource.placeOrder(order: model);
      return Success(created);
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر إرسال أمر الشراء: $e'));
    }
  }

  @override
  Stream<List<OrderEntity>> watchMyOrders({
    required String retailerId,
    int limit = 20,
  }) {
    return _remoteDataSource.watchMyOrders(
      retailerId: retailerId,
      limit: limit,
    );
  }

  @override
  Future<ApiResult<OrdersPageResult>> getMyOrdersPage({
    required String retailerId,
    int limit = 20,
    dynamic startAfterDocument,
  }) async {
    try {
      final pageData = await _remoteDataSource.getMyOrdersPage(
        retailerId: retailerId,
        limit: limit,
        startAfterDocument:
            startAfterDocument as DocumentSnapshot<Map<String, dynamic>>?,
      );

      return Success(
        OrdersPageResult(
          orders: pageData.orders,
          lastDocument: pageData.lastDocument,
          hasMore: pageData.hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر جلب صفحة الطلبات: $e'));
    }
  }

  @override
  Stream<OrderEntity?> watchOrder({required String orderId}) {
    return _remoteDataSource.watchOrder(orderId: orderId);
  }

  @override
  Future<ApiResult<Unit>> cancelOrder({
    required String orderId,
    required String retailerId,
  }) async {
    try {
      await _remoteDataSource.cancelOrder(orderId: orderId);
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر إلغاء الطلب: $e'));
    }
  }

  @override
  Stream<List<OrderEntity>> watchPendingOrdersForWholesaler({
    required String wholesalerId,
    int limit = 50,
  }) {
    return _remoteDataSource.watchPendingOrdersForWholesaler(
      wholesalerId: wholesalerId,
      limit: limit,
    );
  }

  @override
  Future<ApiResult<OrdersPageResult>> getWholesalerOrdersPage({
    required String wholesalerId,
    OrderStatus? status,
    int limit = 20,
    dynamic startAfterDocument,
  }) async {
    try {
      final pageData = await _remoteDataSource.getWholesalerOrdersPage(
        wholesalerId: wholesalerId,
        status: status?.name,
        limit: limit,
        startAfterDocument:
            startAfterDocument as DocumentSnapshot<Map<String, dynamic>>?,
      );

      return Success(
        OrdersPageResult(
          orders: pageData.orders,
          lastDocument: pageData.lastDocument,
          hasMore: pageData.hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر جلب طلبات المورد: $e'));
    }
  }

  @override
  Future<ApiResult<Unit>> approveOrder({
    required OrderEntity order,
    required PaymentType paymentType,
    required String currentUid,
  }) async {
    try {
      final model = order is OrderModel ? order : OrderModel.fromEntity(order);
      await _remoteDataSource.approveOrder(
        order: model,
        paymentType: paymentType,
        currentUid: currentUid,
      );
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر اعتماد أمر الشراء: $e'));
    }
  }

  @override
  Future<ApiResult<Unit>> rejectOrder({
    required String orderId,
    required String rejectionReason,
  }) async {
    try {
      await _remoteDataSource.rejectOrder(
        orderId: orderId,
        rejectionReason: rejectionReason,
      );
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر رفض أمر الشراء: $e'));
    }
  }

  @override
  Future<ApiResult<Unit>> deliverOrder({
    required String orderId,
  }) async {
    try {
      await _remoteDataSource.deliverOrder(orderId: orderId);
      return const Success(Unit());
    } on FirebaseException catch (e) {
      return ApiFailure(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return ApiFailure(ServerFailure('تعذّر تسليم أمر الشراء: $e'));
    }
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية لإنشاء أو تعديل هذا الطلب.';
      case 'not-found':
        return 'الطلب المطلوب غير موجود أو تم حذفه.';
      case 'unavailable':
        return 'تعذّر الاتصال بخادم قاعدة البيانات، تحقق من الإنترنت.';
      default:
        return e.message ?? 'حدث خطأ في قاعدة البيانات (${e.code})';
    }
  }
}

