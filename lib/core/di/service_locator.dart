import 'package:get_it/get_it.dart';
import '../../services/api_service.dart';
import '../../services/driver_api_service.dart';
import '../../services/sales_api_service.dart';
import '../../services/auth_service.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Core services
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<ApiService>()),
  );

  // Feature services
  getIt.registerLazySingleton<DriverApiService>(
    () => DriverApiService(getIt<ApiService>()),
  );

  getIt.registerLazySingleton<SalesApiService>(
    () => SalesApiService(getIt<ApiService>()),
  );
}
