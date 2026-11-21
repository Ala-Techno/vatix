import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

/// Parameters for approving a purchase order
class ApproveOrderParams {
  final OrderEntity order;
  final PaymentType paymentType;
  final String wholesalerUid;

  const ApproveOrderParams({
    required this.order,
    required this.paymentType,
    required this.wholesalerUid,
  });
}

/// [ApproveOrderUseCase] — Use case for approving a purchase order by wholesaler (Task 4.5)
class ApproveOrderUseCase {
  final OrdersRepository _repository;

  ApproveOrderUseCase(this._repository);

  Future<ApiResult<Unit>> call(ApproveOrderParams params) async {
    // 1. Verify that order is in pending status only
    if (params.order.status != OrderStatus.pending) {
      return ApiFailure(
        const ValidationFailure('لا يمكن اعتماد طلب غير معلّق.'),
      );
    }

    // 2. Verify wholesaler identity
    if (params.wholesalerUid.trim().isEmpty ||
        params.wholesalerUid != params.order.wholesalerId) {
      return ApiFailure(
        const ValidationFailure('أنت لست المورد المخوّل باعتماد هذا الطلب.'),
      );
    }

    // 3. Verify presence of valid financial totals
    if (params.order.totals.isEmpty) {
      return ApiFailure(
        const ValidationFailure('الطلب لا يحتوي على مبالغ أو إجماليات صالحة.'),
      );
    }

    return _repository.approveOrder(
      order: params.order,
      paymentType: params.paymentType,
      currentUid: params.wholesalerUid,
    );
  }
}

