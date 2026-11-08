import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import 'package:vatix/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<ApiResult<Unit>> call(String email) async {
    return await repository.sendPasswordResetEmail(email);
  }
}