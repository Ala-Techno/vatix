import 'package:vatix/core/errors/api_error_handler.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/invite_code_entity.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_data_source.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource _remoteDataSource;

  CustomersRepositoryImpl({
    required CustomersRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<CustomerEntity>> watchCustomers({
    required String wholesalerId,
    required RetailerStatus status,
  }) {
    return _remoteDataSource.watchCustomers(
      wholesalerId: wholesalerId,
      status: status.toFirestoreString(),
    );
  }

  @override
  Future<ApiResult<Unit>> setCustomerStatus({
    required String customerId,
    required RetailerStatus status,
  }) async {
    try {
      await _remoteDataSource.setCustomerStatus(
        customerId: customerId,
        status: status.toFirestoreString(),
      );
      return const Success(unit);
    } catch (e) {
      return ApiFailure(ApiErrorHandler.handle(e));
    }
  }

  @override
  Stream<InviteCodeEntity?> watchActiveInvite({
    required String wholesalerId,
  }) {
    return _remoteDataSource.watchActiveInvite(wholesalerId: wholesalerId);
  }

  @override
  Future<ApiResult<String>> rotateInvite({
    required String wholesalerId,
  }) async {
    try {
      final newCode = await _remoteDataSource.rotateInvite(
        wholesalerId: wholesalerId,
      );
      return Success(newCode);
    } catch (e) {
      return ApiFailure(ApiErrorHandler.handle(e));
    }
  }
}

