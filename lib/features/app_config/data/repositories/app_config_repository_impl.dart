import '../../domain/models/app_config_model.dart';
import '../../domain/repositories/app_config_repository.dart';

/// Temporary fallback implementation used until the backend is ready.
///
/// BACKEND INTEGRATION:
///   1. Inject Dio (or your HTTP client) via the constructor.
///   2. Replace the body of [getConfig] with:
///        final response = await _apiClient.get('/app/config');
///        return AppConfigModel.fromJson(response.data as Map\<String, dynamic\>);
///   3. No changes to [AppConfigRepository], providers, or any UI file are needed.
class AppConfigRepositoryImpl implements AppConfigRepository {
  const AppConfigRepositoryImpl();

  @override
  Future<AppConfigModel> getConfig() async {
    return AppConfigModel.fallback;
  }
}
