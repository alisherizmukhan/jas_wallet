import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/event.dart';
import '../providers/event_follow_provider.dart';

/// Bell control that toggles event-reminder opt-in for [event].
///
/// Two visual treatments:
///  * [EventFollowBellStyle.appBar] — 40px circle over the details hero.
///  * [EventFollowBellStyle.card] — 32px circle over the listing thumbnail.
class EventFollowBell extends ConsumerWidget {
  const EventFollowBell({
    required this.event,
    this.style = EventFollowBellStyle.appBar,
    super.key,
  });

  final NuEvent event;
  final EventFollowBellStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(eventFollowProvider).contains(event.reminderKey);
    final l10n = AppLocalizations.of(context);

    final size = style == EventFollowBellStyle.appBar ? 40.0 : 32.0;
    final iconSize = style == EventFollowBellStyle.appBar ? 20.0 : 16.0;

    return Semantics(
      button: true,
      selected: followed,
      label: followed
          ? (l10n?.events_unfollowTooltip ?? 'Unfollow this event')
          : (l10n?.events_followTooltip ?? 'Follow this event'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final nowFollowed =
              await ref.read(eventFollowProvider.notifier).toggle(event);
          if (!context.mounted) return;
          final loc = AppLocalizations.of(context);
          if (loc == null) return;
          if (nowFollowed) {
            AppToast.showSuccess(context, loc.events_followedToast);
          } else {
            AppToast.showInfo(context, loc.events_unfollowedToast);
          }
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: followed
                ? AppColors.primary
                : Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppIcon(
              AppIcons.notification,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

enum EventFollowBellStyle { appBar, card }
