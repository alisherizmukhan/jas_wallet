import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/notification_item.dart';

/// Fintech-style in-app notification banner (Apple/Revolut aesthetic).
///
/// Slides in from the top when a foreground FCM message arrives.
/// Tapping navigates to the notification's route; the dismiss button or a
/// swipe-up gesture hides it early. Auto-dismissed by the parent after 4 s.
class InAppNotificationBanner extends StatefulWidget {
  const InAppNotificationBanner({
    super.key,
    required this.item,
    required this.onDismiss,
    this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = widget.item.category;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! < -6) {
              _dismiss();
            }
          },
          onTap: () {
            _dismiss();
            widget.onTap?.call();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.df,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.df,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Category icon pill
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppIcon(
                      category.icon,
                      size: 20,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Text content
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.item.message.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.item.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Dismiss button
                  GestureDetector(
                    key: const ValueKey('notification_dismiss_btn'),
                    onTap: _dismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: AppIcon(
                        AppIcons.close,
                        size: 16,
                        color: isDark ? Colors.white38 : AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
