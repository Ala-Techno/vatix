import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import '../entities/customer_entity.dart';
import '../entities/invite_code_entity.dart';

/// [CustomersRepository] — Domain contract for managing customers and wholesaler invite codes
abstract class CustomersRepository {
  /// Real-time stream of retailers associated with the wholesaler, filtered by status
  Stream<List<CustomerEntity>> watchCustomers({
    required String wholesalerId,
    required RetailerStatus status,
  });

  /// Updates customer status (activate active / block blocked)
  Future<ApiResult<Unit>> setCustomerStatus({
    required String customerId,
    required RetailerStatus status,
  });

  /// Real-time stream of the currently active invite code for the wholesaler
  Stream<InviteCodeEntity?> watchActiveInvite({
    required String wholesalerId,
  });

  /// Rotates invite code (generates a new code and deactivates the old one via WriteBatch)
  Future<ApiResult<String>> rotateInvite({
    required String wholesalerId,
  });
}

