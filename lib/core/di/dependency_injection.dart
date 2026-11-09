import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/shared_pref_service.dart';

// --- Auth Feature ---
import '../../features/auth/data/datasources/auth_firebase_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/auth/domain/usecases/register_retailer_use_case.dart';
import '../../features/auth/domain/usecases/reset_password_use_case.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// --- Customers Feature ---
import '../../features/customers/data/datasources/customers_remote_data_source.dart';
import '../../features/customers/data/repositories/customers_repository_impl.dart';
import '../../features/customers/domain/repositories/customers_repository.dart';
import '../../features/customers/presentation/providers/customers_provider.dart';

// --- Products Feature ---
import '../../features/products/data/datasources/products_remote_data_source.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';
import '../../features/products/presentation/providers/retailer_catalog_provider.dart';
import '../../features/products/presentation/providers/wholesaler_products_provider.dart';

final getIt = GetIt.instance;

/// تسجيلات الحقن لـ Vatix (Feature-First)
Future<void> setupGetIt() async {
  // ── 1. Local storage ─────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPrefService>(
    () => SharedPrefService(sharedPreferences),
  );

  // ── 2. Firebase instances ────────────────────────────────────────────────
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ── 3. Auth DataSource ───────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthFirebaseDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // ── 4. Auth Repository ───────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );

  // ── 5. UseCases ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterRetailerUseCase>(
    () => RegisterRetailerUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ResetPasswordUseCase>(
    () => ResetPasswordUseCase(getIt<AuthRepository>()),
  );

  // ── 6. AuthProvider — Singleton (في جذر التطبيق) ─────────────────────────
  getIt.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      authRepository: getIt<AuthRepository>(),
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      registerRetailerUseCase: getIt<RegisterRetailerUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
    ),
  );

  // ── 7. Customers Feature ─────────────────────────────────────────────────
  getIt.registerLazySingleton<CustomersRemoteDataSource>(
    () => CustomersRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<CustomersRepository>(
    () => CustomersRepositoryImpl(
      remoteDataSource: getIt<CustomersRemoteDataSource>(),
    ),
  );
  getIt.registerFactory<CustomersProvider>(
    () => CustomersProvider(
      repository: getIt<CustomersRepository>(),
    ),
  );

  // ── 8. Products Feature ──────────────────────────────────────────────────
  getIt.registerLazySingleton<ProductsRemoteDataSource>(
    () => ProductsRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(
      remoteDataSource: getIt<ProductsRemoteDataSource>(),
    ),
  );
  getIt.registerFactory<WholesalerProductsProvider>(
    () => WholesalerProductsProvider(
      repository: getIt<ProductsRepository>(),
    ),
  );
  getIt.registerFactory<RetailerCatalogProvider>(
    () => RetailerCatalogProvider(
      repository: getIt<ProductsRepository>(),
    ),
  );
}
