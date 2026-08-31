import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// Notification category that maps to hub sections.
/// When a new hub section is added, add a corresponding enum value here
/// and it will automatically appear in notification settings.
enum NotificationCategory {
  general,
  svc,
  news,
  access,
  events,

  /// Orientation Week — currently Photo Quest verification verdicts.
  ///
  /// Deliberately absent from [notificationSettingCategories]: these are
  /// generated on-device in response to something the student did, not pushed
  /// from a `jaswallet_orientation` FCM topic, so a settings toggle would
  /// subscribe them to a topic that does not exist. Add it there if and when
  /// the backend starts pushing Orientation notifications.
  orientation,
}

extension NotificationCategoryX on NotificationCategory {
  /// Display name for settings UI (fallback — prefer l10n in pages).
  String get displayName {
    switch (this) {
      case NotificationCategory.general: return 'General';
      case NotificationCategory.svc:     return 'Meal Pass';
      case NotificationCategory.news:    return 'News & Promotions';
      case NotificationCategory.access:  return 'Campus Access';
      case NotificationCategory.events:  return 'Events';
      case NotificationCategory.orientation: return 'Orientation Week';
    }
  }

  /// Subtitle hint for settings.
  String get subtitle {
    switch (this) {
      case NotificationCategory.general: return 'System and account alerts';
      case NotificationCategory.svc:     return 'Meal balance and menu updates';
      case NotificationCategory.news:    return 'Promotions and offers';
      case NotificationCategory.access:  return 'Door access and turnstile alerts';
      case NotificationCategory.events:  return 'Reminders for events you follow';
      case NotificationCategory.orientation: return 'Photo Quest results and token rewards';
    }
  }

  /// AppIcon data for this category (SF-style via Lucide).
  AppIconData get icon {
    switch (this) {
      case NotificationCategory.general: return AppIcons.notification;
      case NotificationCategory.svc:     return AppIcons.utensils;
      case NotificationCategory.news:    return AppIcons.megaphone;
      case NotificationCategory.access:  return AppIcons.doorOpen;
      case NotificationCategory.events:  return AppIcons.calendar;
      case NotificationCategory.orientation: return AppIcons.camera;
    }
  }

  /// Action button icon for the notification detail sheet.
  AppIconData get actionButtonIcon {
    switch (this) {
      case NotificationCategory.svc:     return AppIcons.qrCode;
      case NotificationCategory.access:  return AppIcons.doorOpen;
      case NotificationCategory.news:    return AppIcons.document;
      case NotificationCategory.general: return AppIcons.openInNew;
      case NotificationCategory.events:  return AppIcons.calendar;
      case NotificationCategory.orientation: return AppIcons.camera;
    }
  }

  /// Accent colour for the icon badge.
  Color get color {
    switch (this) {
      case NotificationCategory.general: return const Color(0xFF0E5BB5);
      case NotificationCategory.svc:     return const Color(0xFF009688);
      case NotificationCategory.news:    return const Color(0xFF607D8B);
      case NotificationCategory.access:  return const Color(0xFF5C6BC0);
      case NotificationCategory.events:  return const Color(0xFFEF6C00);
      // The Orientation Week brand accent, so the feed row reads as part of
      // the same feature the tap lands in.
      case NotificationCategory.orientation: return const Color(0xFF7100FF);
    }
  }
}

/// A single notification item.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.isImportant = false,
    this.actionRoute,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final bool isImportant;

  /// GoRouter path or alias to navigate to on tap. See [NotificationDeepLinkHandler].
  final String? actionRoute;
  final String? imageUrl;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    bool? isImportant,
    String? actionRoute,
    String? imageUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      actionRoute: actionRoute ?? this.actionRoute,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Preference for one notification category toggle.
class NotificationPreference {
  const NotificationPreference({
    required this.category,
    required this.enabled,
  });

  final NotificationCategory category;
  final bool enabled;

  NotificationPreference copyWith({bool? enabled}) {
    return NotificationPreference(
      category: category,
      enabled: enabled ?? this.enabled,
    );
  }
}
