import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/image_utils.dart';
import '../../../../user/domain/entities/user_entity.dart';
import '../../../../user/presentation/providers/user_provider.dart';

/// Revolut-style profile header.
///
/// Large avatar with XP progress ring, level badge, name, username pill,
/// and an edit-profile icon button.
class ProfileHeaderNew extends ConsumerWidget {
  const ProfileHeaderNew({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Fine-grained selects — only rebuild when these specific fields change.
    final avatarUrl = ref.watch(
      userProvider.select((s) => s.valueOrNull?.avatarUrl ?? user.avatarUrl),
    );
    final fullName = ref.watch(
      userProvider.select((s) => s.valueOrNull?.fullName ?? user.fullName),
    );
    final username = ref.watch(
      userProvider.select((s) => s.valueOrNull?.displayUsername ?? user.displayUsername),
    );
    final bio = ref.watch(
      userProvider.select((s) => s.valueOrNull?.bio ?? user.bio),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // ── Avatar row ───────────────────────────────────────────────────
          _Avatar(avatarUrl: avatarUrl, initials: user.initials),

          const SizedBox(height: 16),

          // ── Name ─────────────────────────────────────────────────────────
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: 6),

          // ── Username ──────────────────────────────────────────────────────
          Text(
            username,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),

          // ── Bio ───────────────────────────────────────────────────────────
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey),
            ),
          ],

        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.initials});
  final String? avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 42,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: getAvatarImageProvider(
        avatarUrl,
        cacheWidth: (84 * MediaQuery.of(context).devicePixelRatio).round(),
      ),
      child: avatarUrl == null
          ? Text(
              initials,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            )
          : null,
    );
  }
}

