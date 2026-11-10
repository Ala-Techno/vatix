import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/unit.dart';
import '../repositories/orders_repository.dart';

/// [RejectOrderUseCase] — حالة استخدام رفض أمر الشراء (Task 4.6.1)
class RejectOrderUseCase {
  final OrdersRepository _repository;

  RejectOrderUseCase(this._repository);

  Future<ApiResult<Unit>> call({
    required String orderId,
    required String rejectionReason,
  }) async {
    final reason = rejectionReason.trim();
    // التحقق من أن السبب لا يقل عن 3 أحرف (حسب متطلبات الخطة 4.6.1)
    if (reason.length < 3) {
      return ApiFailure(
        const ValidationFailure('سبب الرفض إلزامي ويجب ألا يقل عن 3 أحرف.'),
      );
    }

    return _repository.rejectOrder(
      orderId: orderId,
      rejectionReason: reason,
    );
  }
}

/// [DeliverOrderUseCase] — حالة استخدام تسليم أمر الشراء (Task 4.6.2)
class DeliverOrderUseCase {
  final OrdersRepository _repository;

  DeliverOrderUseCase(this._repository);

  Future<ApiResult<Unit>> call({required String orderId}) async {
    if (orderId.trim().isEmpty) {
      return ApiFailure(const ValidationFailure('معرّف الطلب غير صالح.'));
    }

    return _repository.deliverOrder(orderId: orderId);
  }
}

