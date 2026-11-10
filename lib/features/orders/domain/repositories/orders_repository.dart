import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/order_entity.dart';

/// [OrdersPageResult] — نتيجة جلب صفحة طلبات مع دعم الـ Pagination
class OrdersPageResult {
  final List<OrderEntity> orders;
  final dynamic lastDocument;
  final bool hasMore;

  const OrdersPageResult({
    required this.orders,
    this.lastDocument,
    required this.hasMore,
  });
}

/// [OrdersRepository] — عقد الـ Domain لإدارة أوامر الشراء
abstract class OrdersRepository {
  /// إرسال أمر شراء جديد وحفظه بحالة pending (مع دعم العمل دون اتصال E3)
  Future<ApiResult<OrderEntity>> placeOrder({
    required OrderEntity order,
  });

  /// استماع حيّ ولحظي لقائمة طلبات التاجر
  Stream<List<OrderEntity>> watchMyOrders({
    required String retailerId,
    int limit = 20,
  });

  /// جلب صفحة طلبات إضافية مع الـ Pagination
  Future<ApiResult<OrdersPageResult>> getMyOrdersPage({
    required String retailerId,
    int limit = 20,
    dynamic startAfterDocument,
  });

  /// استماع حيّ لتفاصيل وحالة طلب محدد
  Stream<OrderEntity?> watchOrder({
    required String orderId,
  });

  /// إلغاء الطلب من قبل التاجر (مسموح فقط في حالة pending)
  Future<ApiResult<Unit>> cancelOrder({
    required String orderId,
    required String retailerId,
  });

  /// استماع لحظي للطلبات المعلقة للمورد (الحد الأقصى 50) للـ Dashboard والـ Badge
  Stream<List<OrderEntity>> watchPendingOrdersForWholesaler({
    required String wholesalerId,
    int limit = 50,
  });

  /// جلب صفحة من الطلبات الواردة للمورد مع الـ Pagination وإمكانية الفلترة بالحالة
  Future<ApiResult<OrdersPageResult>> getWholesalerOrdersPage({
    required String wholesalerId,
    OrderStatus? status,
    int limit = 20,
    dynamic startAfterDocument,
  });

  /// اعتماد أمر الشراء ذرياً مع كتابة قيود الدفتر وتحديث الحسابات (Task 4.5)
  Future<ApiResult<Unit>> approveOrder({
    required OrderEntity order,
    required PaymentType paymentType,
    required String currentUid,
  });

  /// رفض أمر الشراء مع سبب إلزامي (Task 4.6.1)
  Future<ApiResult<Unit>> rejectOrder({
    required String orderId,
    required String rejectionReason,
  });

  /// تأكيد تسليم أمر الشراء للتاجر (Task 4.6.2)
  Future<ApiResult<Unit>> deliverOrder({
    required String orderId,
  });
}

