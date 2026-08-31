import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/salto_platform_channel.dart';
import '../providers/salto_activation_provider.dart';

/// Outcome of [SaltoActivationPrerequisites.ensureReady].
enum SaltoPrerequisiteResult {
  /// Every prerequisite is satisfied — proceed immediately.
  ready,

  /// The user was sent to a system Settings screen. Nothing should happen
  /// this tap; expect an automatic readiness refresh (and possibly a
  /// retry) the moment the app resumes.
  wentToSettings,

  /// The user chose not to continue (or dismissed a hard-gate dialog with
  /// no way to proceed, e.g. no internet).
  cancelled,
}

/// Shared, presentation-only orchestration for the two prerequisite checks
/// that run between the user confirming "Enable Mobile Access" and the
/// actual `POST /salto/me/activate-mobile` call:
///
///  • Bluetooth readiness — *soft*. Activation itself never touches
///    Bluetooth, but the mobile key is unusable without it immediately
///    afterward, so this warns and offers "Continue Anyway" rather than
///    blocking outright.
///  • Internet connectivity — *hard*. The POST cannot succeed offline, so
///    this never lets the user proceed without a connection.
///
/// Used identically by both activation entry points (the dedicated
/// login-flow page and the Access page's reactivation prompt) so the
/// dialogs, copy, and logging live in exactly one place. Every dialog uses
/// the existing [AppPremiumDialog] — no new visual language is introduced.
class SaltoActivationPrerequisites {
  SaltoActivationPrerequisites._();

  /// Which settings screen the most recent [wentToSettings]-returning call
  /// opened — `'bluetooth'` or `'network'`. Read by the calling page right
  /// after `ensureReady` returns so the app-resume handler can fire the
  /// matching `SALTO Bluetooth/Network Settings Returned` event; kept as a
  /// small static signal rather than widening [SaltoPrerequisiteResult]'s
  /// shape for a single analytics-only need.
  static String? lastSettingsTypeOpened;

  /// Runs both checks in order.
  ///
  /// [SaltoPrerequisiteResult.ready] — proceed to
  /// [SaltoActivationNotifier.activate] immediately.
  /// [SaltoPrerequisiteResult.wentToSettings] — the user was sent to a
  /// system Settings screen; the calling page should expect an automatic
  /// readiness refresh (and may retry) the moment the app resumes — never
  /// require reopening the page or a manual refresh tap.
  /// [SaltoPrerequisiteResult.cancelled] — the user chose not to continue;
  /// nothing further should happen this tap.
  static Future<SaltoPrerequisiteResult> ensureReady(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bluetoothResult = await _checkBluetooth(context, ref);
    if (bluetoothResult != SaltoPrerequisiteResult.ready) return bluetoothResult;
    if (!context.mounted) return SaltoPrerequisiteResult.cancelled;

    return _checkInternet(context, ref);
  }

  // ── Bluetooth (soft) ────────────────────────────────────────────────────

  static Future<SaltoPrerequisiteResult> _checkBluetooth(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = await SaltoPlatformChannel.bluetoothState();
    if (state == SaltoBluetoothState.ready) return SaltoPrerequisiteResult.ready;
    if (!context.mounted) return SaltoPrerequisiteResult.cancelled;

    final lang = Localizations.localeOf(context).languageCode;
    final notifier = ref.read(saltoActivationProvider.notifier);
    unawaited(notifier.logBlocked('bluetooth_${state.name}', detail: 'Bluetooth state: $state'));
    SaltoAnalytics.instance.trackActivationBlocked(
      reason: 'bluetooth_${state.name}',
      failureStage: 'bluetooth',
    );

    final wentToSettings = await AppPremiumDialog.show(
      context: context,
      icon: AppIcons.bluetoothOff,
      iconColor: const Color(0xFF007AFF),
      title: _bluetoothTitle(lang),
      description: _bluetoothMessage(lang, state),
      confirmText: _openBluetoothSettingsLabel(lang),
      cancelText: _continueAnywayLabel(lang),
    );

    if (!wentToSettings) {
      // "Continue Anyway" or dismissed — activation proceeds either way
      // (Bluetooth is only needed *after* activation), so this is not an
      // abandoned attempt, just a choice not to fix Bluetooth right now.
      SaltoAnalytics.instance.trackUserCancelledBluetoothDialog();
      SaltoAnalytics.instance.trackUserContinuedWithoutBluetooth();
      return SaltoPrerequisiteResult.ready;
    }
    if (!context.mounted) return SaltoPrerequisiteResult.cancelled;

    unawaited(notifier.logSettingsOpened('bluetooth'));
    SaltoAnalytics.instance.trackBluetoothSettingsOpened(flow: 'activation');
    SaltoAnalytics.instance.trackUserOpenedSettings(settingsType: 'bluetooth');
    lastSettingsTypeOpened = 'bluetooth';
    await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    // Don't proceed on this tap — SaltoActivationReadinessNotifier's
    // resume-triggered refresh (and the page's own didChangeAppLifecycleState
    // hook) re-evaluates automatically the moment the user comes back.
    return SaltoPrerequisiteResult.wentToSettings;
  }

  // ── Internet (hard) ─────────────────────────────────────────────────────

  static Future<SaltoPrerequisiteResult> _checkInternet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final online = await ConnectivityService.isConnected();
    SaltoAnalytics.instance.trackInternetStateObserved(online);
    if (online) return SaltoPrerequisiteResult.ready;
    if (!context.mounted) return SaltoPrerequisiteResult.cancelled;

    final lang = Localizations.localeOf(context).languageCode;
    final notifier = ref.read(saltoActivationProvider.notifier);
    unawaited(notifier.logBlocked('internetUnavailable', detail: 'No internet connection'));
    SaltoAnalytics.instance.trackActivationBlocked(
      reason: 'internetUnavailable',
      failureStage: 'internet',
    );
    SaltoAnalytics.instance.trackActivationBlockedByInternet();

    final wentToSettings = await AppPremiumDialog.show(
      context: context,
      icon: AppIcons.wifiOff,
      iconColor: AppColors.error,
      title: _internetTitle(lang),
      description: _internetMessage(lang),
      confirmText: _openNetworkSettingsLabel(lang),
      cancelText: _cancelLabel(lang),
    );

    if (wentToSettings && context.mounted) {
      unawaited(notifier.logSettingsOpened('network'));
      SaltoAnalytics.instance.trackNetworkSettingsOpened();
      SaltoAnalytics.instance.trackUserOpenedSettings(settingsType: 'network');
      lastSettingsTypeOpened = 'network';
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
      return SaltoPrerequisiteResult.wentToSettings;
    }
    // Internet is a hard requirement — never proceed without it, whichever
    // button was tapped. Declining to fix it abandons the activation
    // attempt entirely for this tap.
    SaltoAnalytics.instance.trackUserCancelledActivation();
    return SaltoPrerequisiteResult.cancelled;
  }

  // ── Copy ─────────────────────────────────────────────────────────────────

  static String _bluetoothTitle(String lang) => switch (lang) {
        'ru' => 'Включите Bluetooth',
        'kk' => 'Bluetooth-ты қосыңыз',
        _ => 'Turn On Bluetooth',
      };

  static String _bluetoothMessage(String lang, SaltoBluetoothState state) {
    final reason = switch (state) {
      SaltoBluetoothState.off => switch (lang) {
          'ru' => 'Bluetooth сейчас выключен.',
          'kk' => 'Bluetooth қазір өшірулі.',
          _ => 'Bluetooth is currently off.',
        },
      SaltoBluetoothState.turningOn ||
      SaltoBluetoothState.turningOff ||
      SaltoBluetoothState.resetting =>
        switch (lang) {
          'ru' => 'Bluetooth еще включается.',
          'kk' => 'Bluetooth әлі қосылып жатыр.',
          _ => 'Bluetooth is still turning on.',
        },
      SaltoBluetoothState.unauthorized => switch (lang) {
          'ru' => 'У приложения нет разрешения на Bluetooth.',
          'kk' => 'Қолданбада Bluetooth рұқсаты жоқ.',
          _ => 'This app does not have Bluetooth permission.',
        },
      SaltoBluetoothState.unsupported => switch (lang) {
          'ru' => 'Это устройство не поддерживает Bluetooth.',
          'kk' => 'Бұл құрылғы Bluetooth-ты қолдамайды.',
          _ => 'This device does not support Bluetooth.',
        },
      SaltoBluetoothState.ready || SaltoBluetoothState.unknown => switch (lang) {
          'ru' => 'Не удалось определить состояние Bluetooth.',
          'kk' => 'Bluetooth күйін анықтау мүмкін болмады.',
          _ => 'Could not determine the current Bluetooth state.',
        },
    };
    final why = switch (lang) {
      'ru' =>
        'Bluetooth понадобится сразу после активации, чтобы открывать турникет телефоном. Включите Bluetooth, чтобы продолжить.',
      'kk' =>
        'Bluetooth белсендіргеннен кейін турникетті телефонмен ашу үшін бірден қажет болады. Жалғастыру үшін Bluetooth-ты қосыңыз.',
      _ =>
        'Bluetooth is required to use your mobile access after activation. Please enable Bluetooth to continue.',
    };
    return '$reason $why';
  }

  static String _internetTitle(String lang) => switch (lang) {
        'ru' => 'Нет подключения к интернету',
        'kk' => 'Интернет байланысы жоқ',
        _ => 'No Internet Connection',
      };

  static String _internetMessage(String lang) => switch (lang) {
        'ru' => 'Для активации мобильного доступа необходимо подключение к интернету.',
        'kk' => 'Мобильді қолжетімділікті белсендіру үшін интернет байланысы қажет.',
        _ => 'An internet connection is required to activate your mobile access.',
      };

  static String _openBluetoothSettingsLabel(String lang) => switch (lang) {
        'ru' => 'Открыть настройки Bluetooth',
        'kk' => 'Bluetooth баптауларын ашу',
        _ => 'Open Bluetooth Settings',
      };

  static String _openNetworkSettingsLabel(String lang) => switch (lang) {
        'ru' => 'Открыть настройки сети',
        'kk' => 'Желі баптауларын ашу',
        _ => 'Open Network Settings',
      };

  static String _continueAnywayLabel(String lang) => switch (lang) {
        'ru' => 'Продолжить в любом случае',
        'kk' => 'Бәрібір жалғастыру',
        _ => 'Continue Anyway',
      };

  static String _cancelLabel(String lang) => switch (lang) {
        'ru' => 'Отмена',
        'kk' => 'Бас тарту',
        _ => 'Cancel',
      };
}
