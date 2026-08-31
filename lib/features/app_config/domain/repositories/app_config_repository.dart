import '../models/app_config_model.dart';

abstract class AppConfigRepository {
  /// Fetch current app configuration from the backend.
  ///
  /// Returns [AppConfigModel.fallback] until GET /app/config is available.
  Future<AppConfigModel> getConfig();
}
