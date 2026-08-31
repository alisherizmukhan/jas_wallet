import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/utils/image_picker_service.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/kazakh_phone_formatter.dart';
import '../../../../core/utils/username_input_formatter.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../settings/presentation/providers/profile_completion_provider.dart';
import '../../../settings/presentation/providers/section_highlight_provider.dart';
import '../../../settings/presentation/widgets/profile_dashboard/section_highlight_border.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../widgets/avatar_picker_sheet.dart';

/// Edit profile page — all fields are always-editable text inputs.
/// Auto-saves each field when focus leaves the field.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _scrollController = ScrollController();

  // Section keys for auto-scroll from completion banner
  final _dobKey = GlobalKey();
  final _genderKey = GlobalKey();
  final _usernameKey = GlobalKey();
  final _phoneKey = GlobalKey();

  // Controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;

  // Focus nodes
  late final FocusNode _usernameFocus;
  late final FocusNode _phoneFocus;
  late final FocusNode _dobFocus;

  // Gender state
  bool _isGenderExpanded = false;
  bool _isSavingGender = false;

  // Username availability
  bool _isCheckingUsername = false;
  bool _usernameAvailable = false;
  String? _usernameError;
  Timer? _usernameCheckDebounce;
  static const _usernameCheckDelay = Duration(milliseconds: 400);

  // Track last-saved values to avoid duplicate API calls
  String _savedUsername = '';
  String _savedPhone = '';
  String _savedDob = '';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();

    _usernameFocus = FocusNode()..addListener(_onUsernameFocusChange);
    _phoneFocus = FocusNode()..addListener(_onPhoneFocusChange);
    _dobFocus = FocusNode()..addListener(_onDobFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Populate fields from current user
      final user = ref.read(userProvider).valueOrNull;
      if (user != null) _populateFields(user);

      // Handle highlight from completion banner
      final active = ref.read(sectionHighlightProvider);
      if (active.isNotEmpty) {
        ref.read(sectionHighlightProvider.notifier).trigger(active);
        _scrollToSection(active);
      }
    });
  }

  void _populateFields(UserEntity user) {
    _usernameController.text = user.username;
    _savedUsername = user.username;

    _phoneController.text = KazakhPhoneInputFormatter.formatPhone(user.phone ?? '');
    _savedPhone = user.phone ?? '';

    final dob = user.dateOfBirth;
    final dobStr = dob != null
        ? '${dob.day.toString().padLeft(2, '0')}.${dob.month.toString().padLeft(2, '0')}.${dob.year}'
        : '';
    _dobController.text = dobStr;
    _savedDob = dobStr;
  }

  @override
  void dispose() {
    _usernameCheckDebounce?.cancel();
    _usernameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _usernameFocus
      ..removeListener(_onUsernameFocusChange)
      ..dispose();
    _phoneFocus
      ..removeListener(_onPhoneFocusChange)
      ..dispose();
    _dobFocus
      ..removeListener(_onDobFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(Set<ProfileSection> sections) {
    GlobalKey? key;
    if (sections.contains(ProfileSection.dob)) {
      key = _dobKey;
    } else if (sections.contains(ProfileSection.gender)) {
      key = _genderKey;
    } else if (sections.contains(ProfileSection.username)) {
      key = _usernameKey;
    } else if (sections.contains(ProfileSection.phone)) {
      key = _phoneKey;
    }
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  // ─── Auto-save on focus-out ────────────────────────────────────────────────

  void _onUsernameFocusChange() {
    if (!_usernameFocus.hasFocus) _saveUsername();
  }

  void _onPhoneFocusChange() {
    if (!_phoneFocus.hasFocus) _savePhone();
  }

  void _onDobFocusChange() {
    if (!_dobFocus.hasFocus) _saveDob();
  }

  // ─── Save helpers ──────────────────────────────────────────────────────────

  bool _isValidUsername(String v) => RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(v);

  String _normalizeError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').trim();

  /// Debounced, real-time availability check while the user types.
  void _onUsernameChanged(String value) {
    _usernameCheckDebounce?.cancel();
    final username = value.trim().toLowerCase();

    setState(() => _usernameAvailable = false);

    // Unchanged from the saved value — it's the user's own username.
    if (username == _savedUsername) {
      setState(() {
        _isCheckingUsername = false;
        _usernameError = null;
      });
      return;
    }

    if (username.isEmpty || !_isValidUsername(username)) {
      setState(() {
        _isCheckingUsername = false;
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _usernameCheckDebounce =
        Timer(_usernameCheckDelay, () => _checkUsername(username));
  }

  Future<void> _checkUsername(String username) async {
    try {
      final result =
          await ref.read(authRepositoryProvider).checkUsernameAvailable(username);
      if (!mounted ||
          _usernameController.text.trim().toLowerCase() != username) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isCheckingUsername = false;
        if (!result.valid) {
          _usernameAvailable = false;
          _usernameError = l10n.auth_usernameInvalidFormat;
        } else if (!result.available) {
          _usernameAvailable = false;
          _usernameError = l10n.auth_usernameTaken;
        } else {
          _usernameAvailable = true;
          _usernameError = null;
        }
      });
      // If the user already left the field while we were checking, persist now.
      if (_usernameAvailable && !_usernameFocus.hasFocus) {
        await _saveUsername();
      }
    } catch (_) {
      if (!mounted ||
          _usernameController.text.trim().toLowerCase() != username) {
        return;
      }
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailable = false;
        _usernameError = null;
      });
    }
  }

  Future<void> _saveUsername() async {
    if (!mounted) return;
    final draft = _usernameController.text.trim().toLowerCase();
    if (draft == _savedUsername) return;
    if (!_isValidUsername(draft)) {
      if (mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.editProfile_usernameFormatHint,
        );
      }
      return;
    }
    // Only save once the username is confirmed free (avoids a guaranteed 409).
    if (!_usernameAvailable) return;
    try {
      await ref.read(userProvider.notifier).updateProfile(username: draft);
      _savedUsername = draft;
      if (mounted) {
        setState(() => _usernameError = null);
        AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, _normalizeError(e));
    }
  }

  Future<void> _savePhone() async {
    if (!mounted) return;
    final draft = _phoneController.text.trim();

    // Compare by digits so formatted display value and raw API value match.
    final draftDigits = draft.replaceAll(RegExp(r'\D'), '');
    final savedDigits = _savedPhone.replaceAll(RegExp(r'\D'), '');
    if (draftDigits == savedDigits) return;

    // Empty input clears the phone.
    var digits = draftDigits;
    if (digits.isEmpty) {
      await _persistPhone('');
      return;
    }

    // Normalize 8XXXXXXXXXX / 7XXXXXXXXXX / XXXXXXXXXX to a canonical +7XXXXXXXXXX.
    if (digits.length == 11 && (digits.startsWith('8') || digits.startsWith('7'))) {
      digits = '7${digits.substring(1)}';
    } else if (digits.length == 10) {
      digits = '7$digits';
    }

    if (digits.length != 11 || !digits.startsWith('7')) {
      if (mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.editPhone_invalidFormat,
        );
      }
      return;
    }

    await _persistPhone('+$digits');
  }

  Future<void> _persistPhone(String value) async {
    try {
      await ref.read(userProvider.notifier).updateProfile(phone: value);
      _savedPhone = value;
      // Always keep the display formatted after save.
      final formatted = KazakhPhoneInputFormatter.formatPhone(value);
      if (_phoneController.text != formatted) {
        _phoneController.text = formatted;
      }
      if (mounted) {
        AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, _normalizeError(e));
    }
  }

  Future<void> _saveDob() async {
    if (!mounted) return;
    final raw = _dobController.text.trim();
    if (raw == _savedDob) return;
    final parsed = _parseDob(raw);
    if (parsed == null) {
      if (raw.isNotEmpty && mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.editProfile_dateFormatInvalid,
        );
      }
      return;
    }
    try {
      await ref.read(userProvider.notifier).updateProfile(dateOfBirth: parsed);
      _savedDob = raw;
      if (mounted) {
        AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, _normalizeError(e));
    }
  }

  DateTime? _parseDob(String raw) {
    final parts = raw.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.isAfter(DateTime.now())) return null;
    return date;
  }

  Future<void> _saveGender(BuildContext ctx, String gender) async {
    final l10n = AppLocalizations.of(ctx)!;
    setState(() {
      _isSavingGender = true;
      _isGenderExpanded = false;
    });
    try {
      await ref.read(userProvider.notifier).updateProfile(gender: gender);
      if (ctx.mounted) AppToast.showSuccess(ctx, l10n.common_saved);
    } catch (e) {
      if (ctx.mounted) AppToast.showError(ctx, _normalizeError(e));
    } finally {
      if (mounted) setState(() => _isSavingGender = false);
    }
  }

  // ─── Avatar picker ─────────────────────────────────────────────────────────

  void _showAvatarPicker(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final hasAvatar =
        ref.read(userProvider).valueOrNull?.avatarUrl?.trim().isNotEmpty ??
            false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => AvatarPickerSheet(
        onCameraSelected: () async {
          Navigator.pop(sheetCtx);
          final result = await ImagePickerService().pickFromCamera(
            preferredCameraDevice: CameraDevice.front,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          if (result.isSuccess && result.path != null) {
            final cropped =
                await ImagePickerService().cropImage(result.path!);
            if (cropped.isSuccess && cropped.path != null) {
              try {
                await ref
                    .read(userProvider.notifier)
                    .updateAvatar(cropped.path!);
                if (ctx.mounted) {
                  AppToast.showSuccess(
                    ctx,
                    AppLocalizations.of(ctx)!.editProfile_avatarUpdated,
                  );
                }
              } catch (_) {
                if (ctx.mounted) {
                  _avatarError(ctx);
                }
              }
            } else if (cropped.error != null && ctx.mounted) {
              _avatarError(ctx);
            }
          } else if (result.error != null && ctx.mounted) {
            _avatarError(ctx);
          }
        },
        onGallerySelected: () async {
          Navigator.pop(sheetCtx);
          final result = await ImagePickerService().pickFromGallery(
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          if (result.isSuccess && result.path != null) {
            final cropped =
                await ImagePickerService().cropImage(result.path!);
            if (cropped.isSuccess && cropped.path != null) {
              try {
                await ref
                    .read(userProvider.notifier)
                    .updateAvatar(cropped.path!);
                if (ctx.mounted) {
                  AppToast.showSuccess(
                    ctx,
                    AppLocalizations.of(ctx)!.editProfile_avatarUpdated,
                  );
                }
              } catch (_) {
                if (ctx.mounted) {
                  _avatarError(ctx);
                }
              }
            } else if (cropped.error != null && ctx.mounted) {
              _avatarError(ctx);
            }
          } else if (result.error != null && ctx.mounted) {
            _avatarError(ctx);
          }
        },
        onRemoveSelected: hasAvatar
            ? () async {
                Navigator.pop(sheetCtx);
                try {
                  await ref.read(userProvider.notifier).deleteAvatar();
                  if (ctx.mounted) {
                    AppToast.showSuccess(
                      ctx,
                      AppLocalizations.of(ctx)!.common_saved,
                    );
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    _avatarError(ctx);
                  }
                }
              }
            : null,
      ),
    );
  }

  void _avatarError(BuildContext ctx) => AppToast.showError(
        ctx,
        AppLocalizations.of(ctx)!.editProfile_avatarUpdateFailed,
      );

  String _localizedGender(BuildContext ctx, String? g) {
    final l10n = AppLocalizations.of(ctx)!;
    return switch (g) {
      'male' => l10n.editProfile_male,
      'female' => l10n.editProfile_female,
      'other' => l10n.editProfile_other,
      _ => l10n.common_notSpecified,
    };
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.profile_editProfile,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.profile_errorGeneric)),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.common_userNotFound));
          }
          return _buildForm(context, user, l10n, isLight, theme);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    UserEntity user,
    AppLocalizations l10n,
    bool isLight,
    ThemeData theme,
  ) {
    final fieldBg = isLight ? const Color(0xFFF2F2F7) : AppColors.surfaceDark;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // ── Avatar row ───────────────────────────────────────────────────
          Row(
            children: [
              SectionHighlightBorder(
                section: ProfileSection.photo,
                borderRadius: 36,
                child: GestureDetector(
                  onTap: () => _showAvatarPicker(context),
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                          border: Border.all(
                            color: AppColors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: user.avatarUrl != null
                            ? ClipOval(
                                child: Image(
                                  image: getAvatarImageProvider(
                                    user.avatarUrl,
                                    cacheWidth: (72 * MediaQuery.of(context).devicePixelRatio).round(),
                                  ),
                                  fit: BoxFit.cover,
                                  width: 72,
                                  height: 72,
                                ),
                              )
                            : Center(
                                child: AppIcon(
                                  AppIcons.addAvatar,
                                  size: 28,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const AppIcon(
                            AppIcons.edit,
                            size: 12,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.displayUsername,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            l10n.editProfile_accountData,
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          // ── DOB ──────────────────────────────────────────────────────────
          Padding(
            key: _dobKey,
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionHighlightBorder(
              section: ProfileSection.dob,
              child: _FormField(
                label: l10n.editProfile_dateOfBirth,
                controller: _dobController,
                focusNode: _dobFocus,
                hint: l10n.editProfile_dateFormatHint,
                keyboardType: TextInputType.number,
                formatters: [_DobInputFormatter()],
                fieldBg: fieldBg,
                isLight: isLight,
              ),
            ),
          ),

          // ── Gender ───────────────────────────────────────────────────────
          Padding(
            key: _genderKey,
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionHighlightBorder(
              section: ProfileSection.gender,
              child: _GenderField(
                currentGender: user.gender,
                isLight: isLight,
                isSaving: _isSavingGender,
                isExpanded: _isGenderExpanded,
                onToggle: () =>
                    setState(() => _isGenderExpanded = !_isGenderExpanded),
                onSelect: (g) => _saveGender(context, g),
                localizedGender: (g) => _localizedGender(context, g),
                notSpecifiedLabel: l10n.common_notSpecified,
                fieldBg: fieldBg,
              ),
            ),
          ),

          // ── Username ─────────────────────────────────────────────────────
          Padding(
            key: _usernameKey,
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHighlightBorder(
                  section: ProfileSection.username,
                  child: _FormField(
                    label: l10n.auth_username,
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    hint: l10n.auth_usernameHint,
                    autocorrect: false,
                    formatters: [UsernameInputFormatter()],
                    onChanged: _onUsernameChanged,
                    fieldBg: fieldBg,
                    isLight: isLight,
                  ),
                ),
                if (_isCheckingUsername || _usernameError != null || _usernameAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: _isCheckingUsername
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _usernameError ?? l10n.auth_usernameAvailable,
                            style: TextStyle(
                              fontSize: 12,
                              color: _usernameError != null
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                  ),
              ],
            ),
          ),

          // ── Phone ────────────────────────────────────────────────────────
          Padding(
            key: _phoneKey,
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionHighlightBorder(
              section: ProfileSection.phone,
              child: _FormField(
                label: l10n.editProfile_phoneNumber,
                controller: _phoneController,
                focusNode: _phoneFocus,
                hint: l10n.editProfile_phoneHint,
                keyboardType: TextInputType.phone,
                formatters: [KazakhPhoneInputFormatter()],
                fieldBg: fieldBg,
                isLight: isLight,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Plain form field (Revolut style) ─────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.fieldBg,
    required this.isLight,
    this.keyboardType = TextInputType.text,
    this.autocorrect = true,
    this.formatters,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final TextInputType keyboardType;
  final bool autocorrect;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final Color fieldBg;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            focusNode: focusNode,
            autocorrect: autocorrect,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.done,
            inputFormatters: formatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gender inline field ──────────────────────────────────────────────────────

class _GenderField extends StatelessWidget {
  const _GenderField({
    required this.currentGender,
    required this.isLight,
    required this.isSaving,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelect,
    required this.localizedGender,
    required this.notSpecifiedLabel,
    required this.fieldBg,
  });

  final String? currentGender;
  final bool isLight;
  final bool isSaving;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;
  final String Function(String?) localizedGender;
  final String notSpecifiedLabel;
  final Color fieldBg;

  static const _options = ['male', 'female', 'other'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — always visible
          GestureDetector(
            onTap: isSaving ? null : onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editProfile_gender,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                localizedGender(currentGender),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const AppIcon(
                      AppIcons.chevronDown,
                      size: 16,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded options
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isLight
                      ? AppColors.borderGrey
                      : AppColors.borderDark,
                ),
                ..._options.map(
                  (opt) => _GenderOption(
                    label: localizedGender(opt),
                    isSelected: currentGender == opt,
                    onTap: () => onSelect(opt),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Auto-inserts dots to produce dd.mm.yyyy as the user types digits.
class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
    }
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) buf.write('.');
      buf.write(capped[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected
                        ? AppColors.primary
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
