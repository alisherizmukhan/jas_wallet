import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../../user/presentation/providers/user_provider.dart';

const _kDesignKeyPrefix = 'salto_student_card_design_';
const _kCustomDesignImageKeyPrefix = 'salto_student_card_custom_image_';

enum SaltoStudentCardDesign {
  classicGold,
  blueOrbit,
  emeraldWave,
  sunsetBlaze,
  arcticFrost,
  carbonNight,
  // NU-specific school designs
  nuDefault,
  nuGsb,
  nuNusom,
  nuSeds,
  nuSmg,
  nuSsh,
  custom,
}

extension SaltoStudentCardDesignX on SaltoStudentCardDesign {
  String get storageKey {
    switch (this) {
      case SaltoStudentCardDesign.classicGold:
        return 'classic_gold';
      case SaltoStudentCardDesign.blueOrbit:
        return 'blue_orbit';
      case SaltoStudentCardDesign.emeraldWave:
        return 'emerald_wave';
      case SaltoStudentCardDesign.sunsetBlaze:
        return 'sunset_blaze';
      case SaltoStudentCardDesign.arcticFrost:
        return 'arctic_frost';
      case SaltoStudentCardDesign.carbonNight:
        return 'carbon_night';
      case SaltoStudentCardDesign.nuDefault:
        return 'nu_default';
      case SaltoStudentCardDesign.nuGsb:
        return 'nu_gsb';
      case SaltoStudentCardDesign.nuNusom:
        return 'nu_nusom';
      case SaltoStudentCardDesign.nuSeds:
        return 'nu_seds';
      case SaltoStudentCardDesign.nuSmg:
        return 'nu_smg';
      case SaltoStudentCardDesign.nuSsh:
        return 'nu_ssh';
      case SaltoStudentCardDesign.custom:
        return 'custom';
    }
  }

  /// Whether this is an NU-branded school design
  bool get isNuDesign {
    switch (this) {
      case SaltoStudentCardDesign.nuDefault:
      case SaltoStudentCardDesign.nuGsb:
      case SaltoStudentCardDesign.nuNusom:
      case SaltoStudentCardDesign.nuSeds:
      case SaltoStudentCardDesign.nuSmg:
      case SaltoStudentCardDesign.nuSsh:
        return true;
      default:
        return false;
    }
  }

  /// Background asset path for NU designs
  String? get nuBackgroundAsset {
    switch (this) {
      case SaltoStudentCardDesign.nuDefault:
        return 'assets/nu_card_templates/schools/default.png';
      case SaltoStudentCardDesign.nuGsb:
        return 'assets/nu_card_templates/schools/gsb.png';
      case SaltoStudentCardDesign.nuNusom:
        return 'assets/nu_card_templates/schools/nusom.png';
      case SaltoStudentCardDesign.nuSeds:
        return 'assets/nu_card_templates/schools/seds.png';
      case SaltoStudentCardDesign.nuSmg:
        return 'assets/nu_card_templates/schools/smg.png';
      case SaltoStudentCardDesign.nuSsh:
        return 'assets/nu_card_templates/schools/ssh.png';
      default:
        return null;
    }
  }

  /// Display label for each design
  String get label {
    switch (this) {
      case SaltoStudentCardDesign.nuDefault:
        return 'NU Default';
      case SaltoStudentCardDesign.nuGsb:
        return 'GSB';
      case SaltoStudentCardDesign.nuNusom:
        return 'NUSOM';
      case SaltoStudentCardDesign.nuSeds:
        return 'SEDS';
      case SaltoStudentCardDesign.nuSmg:
        return 'SMG';
      case SaltoStudentCardDesign.nuSsh:
        return 'SSH';
      case SaltoStudentCardDesign.classicGold:
        return 'Classic Gold';
      case SaltoStudentCardDesign.blueOrbit:
        return 'Blue Orbit';
      case SaltoStudentCardDesign.emeraldWave:
        return 'Emerald Wave';
      case SaltoStudentCardDesign.sunsetBlaze:
        return 'Sunset Blaze';
      case SaltoStudentCardDesign.arcticFrost:
        return 'Arctic Frost';
      case SaltoStudentCardDesign.carbonNight:
        return 'Carbon Night';
      case SaltoStudentCardDesign.custom:
        return 'Custom';
    }
  }

  static SaltoStudentCardDesign fromStorageKey(String? value) {
    for (final design in SaltoStudentCardDesign.values) {
      if (design.storageKey == value) return design;
    }
    return SaltoStudentCardDesign.classicGold;
  }

  /// All NU school designs (for template picker)
  static List<SaltoStudentCardDesign> get nuDesigns => [
    SaltoStudentCardDesign.nuDefault,
    SaltoStudentCardDesign.nuGsb,
    SaltoStudentCardDesign.nuNusom,
    SaltoStudentCardDesign.nuSeds,
    SaltoStudentCardDesign.nuSmg,
    SaltoStudentCardDesign.nuSsh,
  ];

  /// All generic designs (non-NU, non-custom)
  static List<SaltoStudentCardDesign> get genericDesigns => [
    SaltoStudentCardDesign.classicGold,
    SaltoStudentCardDesign.blueOrbit,
    SaltoStudentCardDesign.emeraldWave,
    SaltoStudentCardDesign.sunsetBlaze,
    SaltoStudentCardDesign.arcticFrost,
    SaltoStudentCardDesign.carbonNight,
  ];
}

class SaltoStudentCardState {
  const SaltoStudentCardState({
    this.selectedDesign = SaltoStudentCardDesign.classicGold,
    this.customDesignImagePath,
    this.activeStudentKey,
    this.resolvedEmail,
    this.isLoaded = false,
  });

  final SaltoStudentCardDesign selectedDesign;
  final String? customDesignImagePath;
  final String? activeStudentKey;
  final String? resolvedEmail;
  final bool isLoaded;

  SaltoStudentCardState copyWith({
    SaltoStudentCardDesign? selectedDesign,
    String? customDesignImagePath,
    bool clearCustomDesignImage = false,
    String? activeStudentKey,
    bool clearActiveStudentKey = false,
    String? resolvedEmail,
    bool clearResolvedEmail = false,
    bool? isLoaded,
  }) {
    return SaltoStudentCardState(
      selectedDesign: selectedDesign ?? this.selectedDesign,
      customDesignImagePath: clearCustomDesignImage
          ? null
          : customDesignImagePath ?? this.customDesignImagePath,
      activeStudentKey: clearActiveStudentKey
          ? null
          : activeStudentKey ?? this.activeStudentKey,
      resolvedEmail: clearResolvedEmail
          ? null
          : resolvedEmail ?? this.resolvedEmail,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SaltoStudentCardNotifier extends StateNotifier<SaltoStudentCardState> {
  SaltoStudentCardNotifier() : super(const SaltoStudentCardState());

  int _loadVersion = 0;

  void clearForSignedOut() {
    _loadVersion++;

    // Logout/switch-account boundary: wipe persisted Salto card artifacts.
    unawaited(_clearPersistedCardStorage());

    final isDefaultState =
        state.selectedDesign == SaltoStudentCardDesign.classicGold &&
        state.customDesignImagePath == null &&
        state.activeStudentKey == null &&
        !state.isLoaded;

    if (isDefaultState) return;

    state = const SaltoStudentCardState();
  }

  Future<void> _clearPersistedCardStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_kDesignKeyPrefix) ||
              key.startsWith(_kCustomDesignImageKeyPrefix),
        )
        .toList(growable: false);

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  Future<void> syncForUser(UserEntity? user) async {
    final studentKey = _resolveStudentKey(user);

    if (studentKey == null) {
      // Ignore transient null user values while auth/user providers resolve.
      // We clear state explicitly on signed-out auth statuses.
      return;
    }

    final userEmail = user?.email?.trim().toLowerCase();
    final emailChanged = state.resolvedEmail != userEmail &&
        userEmail != null &&
        userEmail.isNotEmpty;

    if (state.activeStudentKey == studentKey &&
        state.isLoaded &&
        !emailChanged) {
      return;
    }

    // If email just arrived and no explicit user choice was persisted,
    // allow re-evaluation of the default design.
    final forceDefaultReEval = emailChanged && state.isLoaded;

    final loadVersion = ++_loadVersion;
    final prefs = await SharedPreferences.getInstance();
    final savedDesignKey = prefs.getString('$_kDesignKeyPrefix$studentKey');
    var savedCustomImage = prefs.getString(
      '$_kCustomDesignImageKeyPrefix$studentKey',
    );

    // Determine the default design based on university email
    final isNuStudent = _isNuStudent(user);
    final defaultDesign = isNuStudent
        ? SaltoStudentCardDesign.nuDefault
        : SaltoStudentCardDesign.classicGold;

    var selectedDesign = savedDesignKey != null
        ? SaltoStudentCardDesignX.fromStorageKey(savedDesignKey)
        : defaultDesign;

    // If the email just arrived and the user never explicitly chose a design,
    // switch to the correct default for their university.
    if (forceDefaultReEval && savedDesignKey == null) {
      selectedDesign = defaultDesign;
    }

    if (selectedDesign == SaltoStudentCardDesign.custom) {
      final hasPersistedCustomImage = _isValidPersistedCustomImage(
        savedCustomImage,
      );
      if (!hasPersistedCustomImage) {
        selectedDesign = defaultDesign;
        savedCustomImage = null;
        await prefs.setString(
          '$_kDesignKeyPrefix$studentKey',
          defaultDesign.storageKey,
        );
        await prefs.remove('$_kCustomDesignImageKeyPrefix$studentKey');
      }
    }

    if (loadVersion != _loadVersion) return;

    final shouldUpdateState =
        state.activeStudentKey != studentKey ||
        state.selectedDesign != selectedDesign ||
        state.customDesignImagePath != savedCustomImage ||
        !state.isLoaded;

    if (!shouldUpdateState) return;

    state = state.copyWith(
      activeStudentKey: studentKey,
      selectedDesign: selectedDesign,
      customDesignImagePath: savedCustomImage,
      resolvedEmail: userEmail,
      isLoaded: true,
    );
  }

  Future<void> selectDesign(SaltoStudentCardDesign design) async {
    if (state.selectedDesign == design) return;

    state = state.copyWith(
      selectedDesign: design,
      clearCustomDesignImage: design != SaltoStudentCardDesign.custom,
    );

    final studentKey = state.activeStudentKey;
    if (studentKey == null || studentKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kDesignKeyPrefix$studentKey', design.storageKey);

    if (design != SaltoStudentCardDesign.custom) {
      await prefs.remove('$_kCustomDesignImageKeyPrefix$studentKey');
    }
  }

  Future<void> selectCustomDesign(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty) return;

    final persistedCustomImage = await _preparePersistedCustomImage(
      normalizedPath,
    );

    final studentKey = state.activeStudentKey;

    state = state.copyWith(
      selectedDesign: SaltoStudentCardDesign.custom,
      customDesignImagePath: persistedCustomImage,
    );

    if (studentKey == null || studentKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kDesignKeyPrefix$studentKey',
      SaltoStudentCardDesign.custom.storageKey,
    );
    await prefs.setString(
      '$_kCustomDesignImageKeyPrefix$studentKey',
      persistedCustomImage,
    );
  }

  Future<void> clearCustomDesign() async {
    final isNu = _isNuStudentByEmail(state.resolvedEmail);
    final fallbackDesign = isNu
        ? SaltoStudentCardDesign.nuDefault
        : SaltoStudentCardDesign.classicGold;

    state = state.copyWith(
      selectedDesign: fallbackDesign,
      clearCustomDesignImage: true,
    );

    final studentKey = state.activeStudentKey;
    if (studentKey == null || studentKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kDesignKeyPrefix$studentKey',
      fallbackDesign.storageKey,
    );
    await prefs.remove('$_kCustomDesignImageKeyPrefix$studentKey');
  }

  bool _isExistingLocalFile(String? path) {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) return false;

    try {
      final resolvedPath = normalized.startsWith('file://')
          ? Uri.parse(normalized).toFilePath()
          : normalized;
      return File(resolvedPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  bool _isValidPersistedCustomImage(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return false;

    if (_isBase64DataImage(normalized)) return true;

    return _isExistingLocalFile(normalized);
  }

  bool _isBase64DataImage(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
  }

  Future<String> _preparePersistedCustomImage(String imagePath) async {
    if (_isBase64DataImage(imagePath)) return imagePath;

    final resolvedPath = imagePath.startsWith('file://')
        ? Uri.parse(imagePath).toFilePath()
        : imagePath;

    try {
      final file = File(resolvedPath);
      if (!await file.exists()) return imagePath;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return imagePath;

      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (_) {
      return imagePath;
    }
  }

  String? _resolveStudentKey(UserEntity? user) {
    if (user == null) return null;

    final userId = user.id.trim();
    if (userId.isNotEmpty) return userId;

    final studentId = user.studentId?.trim();
    if (studentId != null && studentId.isNotEmpty) return studentId;

    return null;
  }

  /// Check if user belongs to Nazarbayev University by email domain
  static bool _isNuStudent(UserEntity? user) {
    return _isNuStudentByEmail(user?.email);
  }

  static bool _isNuStudentByEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return normalized.endsWith('@nu.edu.kz');
  }
}

final saltoStudentCardProvider =
    StateNotifierProvider<SaltoStudentCardNotifier, SaltoStudentCardState>((
      ref,
    ) {
      final notifier = SaltoStudentCardNotifier();

      ref.listen<AuthState>(authProvider, (previous, next) {
        final status = next.status;
        if (status == AuthStatus.unauthenticated ||
            status == AuthStatus.firstLaunch ||
            status == AuthStatus.needsOnboarding) {
          notifier.clearForSignedOut();
        }
      });

      ref.listen<AsyncValue<UserEntity?>>(userProvider, (previous, next) {
        notifier.syncForUser(next.valueOrNull);
      }, fireImmediately: true);

      return notifier;
    });
