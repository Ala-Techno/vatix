import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/features/auth/domain/entities/user_entity.dart';
import 'package:vatix/features/auth/domain/repositories/auth_repository.dart';

/// UseCase التسجيل — الوحيد الذي يحوي منطقاً يستحق UseCase
class RegisterRetailerUseCase {
  final AuthRepository _repository;

  RegisterRetailerUseCase(this._repository);

  Future<ApiResult<UserEntity>> call({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  }) {
    return _repository.registerRetailer(
      email: email,
      password: password,
      businessName: businessName,
      ownerName: ownerName,
      phone: phone,
      city: city,
      inviteCode: inviteCode,
    );
  }
}

