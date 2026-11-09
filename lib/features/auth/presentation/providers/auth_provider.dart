import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vatix/core/errors/api_result.dart';
import 'package:vatix/core/utils/unit.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_retailer_use_case.dart';
import '../../domain/usecases/reset_password_use_case.dart';

/// حالة الجلسة — تحدد أي شاشة تُعرض في AuthGate
enum AuthStatus {
  unknown, // جارٍ التحقق (عرض مؤشر التحميل)
  signedOut, // لا يوجد مستخدم مسجّل
  noProfile, // مستخدم موجود في Auth لكن لا مستند users (تسجيل لم يكتمل)
  wholesaler, // مورد — يذهب للـ WholesalerShell
  retailerPending, // تاجر بانتظار الموافقة
  retailerActive, // تاجر نشط — يذهب للـ RetailerShell
  retailerBlocked, // تاجر موقوف
}

/// [AuthProvider] — Provider جذري واحد في أعلى الشجرة.
/// مصدر الحقيقة للمستخدم والدور والحالة في التطبيق كله.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RegisterRetailerUseCase _registerRetailerUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  AuthProvider({
    required AuthRepository authRepository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RegisterRetailerUseCase registerRetailerUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _authRepository = authRepository,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _registerRetailerUseCase = registerRetailerUseCase,
        _resetPasswordUseCase = resetPasswordUseCase {
    _init();
  }

  // ─── الحالة ───────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.unknown;
  UserEntity? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Subscriptions ────────────────────────────────────────────────────────
  StreamSubscription<dynamic>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  // ─── تهيئة المستمعين ─────────────────────────────────────────────────────
  void _init() {
    _authSub = _authRepository.watchAuthUser().listen((firebaseUser) {
      _userDocSub?.cancel();
      if (firebaseUser == null) {
        _user = null;
        _setStatus(AuthStatus.signedOut);
      } else {
        _listenToUserDoc(firebaseUser.uid);
      }
    });
  }

  void _listenToUserDoc(String uid) {
    _userDocSub = _authRepository.watchUserDoc(uid).listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          // إذا كان التسجيل قيد التنفيذ الآن والمستند في طور الكتابة — ننتظر
          if (_isLoading) return;
          _user = null;
          _setStatus(AuthStatus.noProfile);
          return;
        }
        try {
          final userModel = UserModel.fromFirestore(snapshot);
          _user = userModel;

          if (userModel.isWholesaler) {
            _setStatus(AuthStatus.wholesaler);
          } else if (userModel.role == UserRole.retailer) {
            switch (userModel.status) {
              case RetailerStatus.active:
                _setStatus(AuthStatus.retailerActive);
                break;
              case RetailerStatus.blocked:
                _setStatus(AuthStatus.retailerBlocked);
                break;
              case RetailerStatus.pending:
              default:
                _setStatus(AuthStatus.retailerPending);
            }
          } else {
            _setStatus(AuthStatus.noProfile);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('AuthProvider _listenToUserDoc error: $e');
          _setStatus(AuthStatus.noProfile);
        }
      },
      onError: (e) {
        if (kDebugMode) debugPrint('AuthProvider watchUserDoc error: $e');
        _setStatus(AuthStatus.noProfile);
      },
    );
  }

  void _setStatus(AuthStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // ─── تسجيل الدخول ────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    final result = await _loginUseCase(email: email, password: password);
    return _handleResult(result);
  }

  // ─── تسجيل تاجر جديد ─────────────────────────────────────────────────────
  Future<bool> registerRetailer({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required String inviteCode,
  }) async {
    _setLoading(true);
    final result = await _registerRetailerUseCase(
      email: email,
      password: password,
      businessName: businessName,
      ownerName: ownerName,
      phone: phone,
      city: city,
      inviteCode: inviteCode,
    );
    return _handleResult(result);
  }

  // ─── تسجيل الخروج ────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _logoutUseCase();
    // watchAuthUser() سيُطلق signedOut تلقائياً
  }

  // ─── إعادة تعيين كلمة المرور ─────────────────────────────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    final result = await _resetPasswordUseCase(email);
    _isLoading = false;
    if (result is Success<Unit>) {
      _errorMessage = null;
      notifyListeners();
      return true;
    } else if (result is ApiFailure<Unit>) {
      _errorMessage = result.failure.message;
      notifyListeners();
      return false;
    }
    return false;
  }

  // ─── مساعدات ─────────────────────────────────────────────────────────────
  bool _handleResult<T>(ApiResult<T> result) {
    _isLoading = false;
    if (result is Success<T>) {
      _errorMessage = null;
      notifyListeners();
      return true;
    } else if (result is ApiFailure<T>) {
      _errorMessage = result.failure.message;
      notifyListeners();
      return false;
    }
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}
