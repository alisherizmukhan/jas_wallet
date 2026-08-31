import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/app_update/data/app_update_remote_config_service.dart';
import 'package:jaswallet_app/features/app_update/domain/entities/app_update_remote_config.dart';
import 'package:jaswallet_app/features/app_update/domain/entities/app_update_status.dart';
import 'package:jaswallet_app/features/app_update/domain/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Stands in for Firebase Remote Config so these tests never touch the
/// network or require Firebase.initializeApp() to have run.
class _FakeRemoteConfigService extends AppUpdateRemoteConfigService {
  _FakeRemoteConfigService(this._config, {this.throwOnFetch = false});

  final AppUpdateRemoteConfig _config;
  final bool throwOnFetch;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> fetchAndActivate() async {
    if (throwOnFetch) throw Exception('network unreachable');
    return true;
  }

  @override
  AppUpdateRemoteConfig getConfig() => _config;
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Jas Wallet',
      packageName: 'com.jaswallet.app',
      version: '1.5.0',
      buildNumber: '10',
      buildSignature: '',
    );
  });

  AppUpdateRemoteConfig configWith({
    String latest = '',
    String minimum = '',
    bool force = false,
  }) {
    return AppUpdateRemoteConfig(
      latestVersion: latest,
      minimumVersion: minimum,
      forceUpdate: force,
      updateTitle: '',
      updateMessage: '',
      updateButton: '',
      laterButton: '',
    );
  }

  test('installed version satisfies latest and minimum -> upToDate', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(
        configWith(latest: '1.5.0', minimum: '1.0.0'),
      ),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.upToDate);
  });

  test('installed version above latest -> upToDate', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(configWith(latest: '1.4.0')),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.upToDate);
  });

  test('installed version below latest, force_update false -> optionalUpdate', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(configWith(latest: '1.6.0')),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.optionalUpdate);
  });

  test('installed version below minimum -> requiredUpdate regardless of force_update', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(
        configWith(latest: '1.6.0', minimum: '1.5.5', force: false),
      ),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.requiredUpdate);
  });

  test('installed version below latest, force_update true -> requiredUpdate', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(
        configWith(latest: '1.6.0', force: true),
      ),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.requiredUpdate);
  });

  test('force_update true but installed version already at latest -> upToDate', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(
        configWith(latest: '1.5.0', force: true),
      ),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.upToDate);
  });

  test('empty Remote Config values (never configured) -> upToDate, never crashes', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(AppUpdateRemoteConfig.empty),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.upToDate);
  });

  test('malformed minimum_version string is ignored, not treated as a block', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(
        configWith(latest: '1.5.0', minimum: 'not-a-version'),
      ),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.upToDate);
  });

  test('Remote Config fetch throwing degrades to upToDate, never crashes', () async {
    final service = AppUpdateService(
      remoteConfigService: _FakeRemoteConfigService(
        configWith(latest: '1.6.0'),
        throwOnFetch: true,
      ),
    );
    final decision = await service.evaluate();
    expect(decision.status, AppUpdateStatus.upToDate);
  });
}
