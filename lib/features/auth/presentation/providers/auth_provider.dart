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

/// Session status — determines which screen is displayed in AuthGate
enum AuthStatus {
  unknown, // Checking session (show loading indicator)
  signedOut, // No logged-in user
  noProfile, // User exists in Auth but has no users document (incomplete registration)
  wholesaler, // Wholesaler — navigates to WholesalerShell
  retailerPending, // Retailer awaiting approval
  retailerActive, // Active retailer — navigates to RetailerShell
  retailerBlocked, // Blocked retailer
}

/// [AuthProvider] — Single root provider at top of the tree.
/// Source of truth for user, role, and auth status across the app.
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

  // ─── State ─────────────────────────────────────────────────────────────
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

  // ─── Initialize Listeners ─────────────────────────────────────────────
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
          // If registration is in progress and document is being written — wait
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

  // ─── Sign In ──────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    final result = await _loginUseCase(email: email, password: password);
    return _handleResult(result);
  }

  // ─── Register New Retailer ───────────────────────────────────────────
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

  // ─── Sign Out ─────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _logoutUseCase();
    // watchAuthUser() will trigger signedOut automatically
  }

  // ─── Password Reset ───────────────────────────────────────────────────
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

  // ─── Helpers ──────────────────────────────────────────────────────────
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
