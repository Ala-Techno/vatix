import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/errors/failures.dart';
import 'package:vatix/core/utils/currency.dart';
import 'package:vatix/core/utils/unit.dart';
import '../entities/ledger_entry_entity.dart';
import '../repositories/ledger_repository.dart';

/// [RecordPaymentUseCase] — Use case for recording a retailer payment (Task 5.4)
class RecordPaymentUseCase {
  final LedgerRepository _repository;

  const RecordPaymentUseCase(this._repository);

  Future<ApiResult<Unit>> call({
    required String wholesalerId,
    required String retailerId,
    required String retailerName,
    required int amount,
    required Currency currency,
    required PaymentMethod method,
    String? reference,
    String? note,
    required String createdBy,
  }) async {
    if (amount <= 0) {
      return const ApiFailure(
        ServerFailure('مبلغ السداد يجب أن يكون أكبر من الصفر'),
      );
    }

    if (wholesalerId.trim().isEmpty || retailerId.trim().isEmpty) {
      return const ApiFailure(
        ServerFailure('بيانات الحساب غير مكتملة'),
      );
    }

    return _repository.recordPayment(
      wholesalerId: wholesalerId,
      retailerId: retailerId,
      retailerName: retailerName,
      amount: amount,
      currency: currency,
      method: method,
      reference: reference,
      note: note,
      createdBy: createdBy,
    );
  }
}
