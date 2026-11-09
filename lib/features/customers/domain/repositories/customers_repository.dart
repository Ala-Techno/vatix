import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import '../entities/customer_entity.dart';
import '../entities/invite_code_entity.dart';

/// [CustomersRepository] — عقد الـ Domain لإدارة العملاء وأكواد الدعوة للمورد
abstract class CustomersRepository {
  /// الاستماع اللحظي لقائمة التجار التابعين للمورد ومصفاة حسب حالتهم
  Stream<List<CustomerEntity>> watchCustomers({
    required String wholesalerId,
    required RetailerStatus status,
  });

  /// تغيير حالة التاجر (قبول active / حظر blocked)
  Future<ApiResult<Unit>> setCustomerStatus({
    required String customerId,
    required RetailerStatus status,
  });

  /// الاستماع لكود الدعوة النشط حالياً للمورد
  Stream<InviteCodeEntity?> watchActiveInvite({
    required String wholesalerId,
  });

  /// تدوير كود الدعوة (إنشاء كود جديد وتعطيل القديم عبر WriteBatch)
  Future<ApiResult<String>> rotateInvite({
    required String wholesalerId,
  });
}

