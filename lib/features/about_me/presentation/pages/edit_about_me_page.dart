import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// Edit About Me page - simple text editor for О себе section
class EditAboutMePage extends ConsumerStatefulWidget {
  const EditAboutMePage({super.key});

  @override
  ConsumerState<EditAboutMePage> createState() => _EditAboutMePageState();
}

class _EditAboutMePageState extends ConsumerState<EditAboutMePage> {
  late TextEditingController _controller;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).valueOrNull;
    final bio = user?.bio ?? '';
    _controller = TextEditingController(text: bio);
    _hasContent = bio.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasContent = _controller.text.trim().isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref.read(userProvider.notifier).updateProfile(
        bio: _controller.text.trim(),
      );
      if (!mounted) return;
      AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      final msg =
          raw.isEmpty || raw == 'null' ? l10n.profile_aboutMeSaveFailed : raw;
      AppToast.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final charCount = _controller.text.length;
    final maxChars = 1000;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.profile_aboutMe,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                  ),
                  boxShadow: isLight
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        maxLength: maxChars,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.profile_addAboutMe,
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: AppColors.grey,
                          ),
                          filled: true,
                          fillColor: isLight ? AppColors.white : AppColors.surfaceDark,
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: isLight
                              ? AppColors.black
                              : AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$charCount / $maxChars',
                        style: TextStyle(
                          fontSize: 12,
                          color: charCount > maxChars * 0.9
                              ? Colors.red
                              : AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasContent ? AppColors.primary : AppColors.secondary,
                  foregroundColor: _hasContent ? Colors.white : AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.common_save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
