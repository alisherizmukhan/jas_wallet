// ignore_for_file: empty_catches
import 'package:app_ui/app_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/events_service.dart';
import '../../domain/entities/event.dart';
import '../widgets/event_follow_bell.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  const EventDetailsPage({required this.event, super.key});
  final NuEvent event;

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  late final Future<NuEventDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = EventsService.instance.fetchEventDetails(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isLight ? const Color(0xFFF5F5FA) : AppColors.surfaceDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _CircleButton(
                  icon: AppIcons.back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                EventFollowBell(event: widget.event),
                if (widget.event.link != null) ...[
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: AppIcons.openInNew,
                    onTap: _openInBrowser,
                  ),
                ],
              ],
            ),
          ),
        ),
        body: FutureBuilder<NuEventDetails>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            final details = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            return _Body(
              event: widget.event,
              details: details,
              isLoading: isLoading,
              isLight: isLight,
              onOpenBrowser: _openInBrowser,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final url = widget.event.link;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scroll body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.event,
    required this.details,
    required this.isLoading,
    required this.isLight,
    required this.onOpenBrowser,
  });

  final NuEvent event;
  final NuEventDetails? details;
  final bool isLoading;
  final bool isLight;
  final VoidCallback onOpenBrowser;

  @override
  Widget build(BuildContext context) {
    final imageUrl = details?.imageUrl ?? event.imageUrl;
    final hasImage = imageUrl != null;
    final cardColor = isLight ? Colors.white : AppColors.surfaceDark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero ──────────────────────────────────────────────────────────
          // AspectRatio(16/9) shows the full image without any cropping.
          // The transparent AppBar floats over the top of this section.
          if (hasImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                // Caps decode size to a large phone's physical width instead
                // of decoding the source image at full (often much larger)
                // resolution into memory.
                memCacheWidth: 1080,
                memCacheHeight: 608,
                placeholder: (ctx, url) => _GradientPlaceholder(
                  category: event.category ?? details?.category,
                ),
                errorWidget: (ctx, url, err) => _GradientPlaceholder(
                  category: event.category ?? details?.category,
                ),
              ),
            )
          else
            _GradientPlaceholder(
              category: event.category ?? details?.category,
              height: 220,
            ),

          // ── Content card (visually overlaps hero by 20px) ─────────────────
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: isLoading
                  ? _LoadingBody(isLight: isLight)
                  : _ContentBody(
                      details: details,
                      event: event,
                      isLight: isLight,
                      onOpenBrowser: onOpenBrowser,
                    ),
            ),
          ),

          // Compensate for the -20px transform so scroll extent is correct
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient hero placeholder (when no image)
// ─────────────────────────────────────────────────────────────────────────────

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.category, this.height});
  final String? category;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final h = height ?? screenWidth * 9 / 16;
    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.5),
            Colors.black45,
          ],
        ),
      ),
      child: Center(
        child: AppIcon(
          AppIcons.calendarMonth,
          size: 60,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content body
// ─────────────────────────────────────────────────────────────────────────────

class _ContentBody extends StatelessWidget {
  const _ContentBody({
    required this.details,
    required this.event,
    required this.isLight,
    required this.onOpenBrowser,
  });

  final NuEventDetails? details;
  final NuEvent event;
  final bool isLight;
  final VoidCallback onOpenBrowser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = details?.title ?? event.title;
    final category = details?.category ?? event.category;
    final categoryColor = _categoryColor(category);
    final date = details?.fullDateTime ?? event.date;
    final location = details?.locationDetails ?? (event.venue.isNotEmpty ? event.venue : null);
    final audience = details?.audience ?? event.audience;
    final about = details?.about ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          if (category != null) ...[
            _CategoryBadge(category: category, color: categoryColor),
            const SizedBox(height: 14),
          ],

          // Title
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isLight ? const Color(0xFF0F0F1A) : AppColors.textColorDark,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          _InfoCard(
            date: date,
            time: event.time,
            location: location,
            audience: audience,
            categoryColor: categoryColor,
            isLight: isLight,
          ),

          // About
          if (about.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionLabel(text: l10n.events_aboutSection, isLight: isLight),
            const SizedBox(height: 12),
            ...about.map((b) => _buildBlock(context, b, isLight)),
          ],

          // Organizer
          if (details?.organizer != null) ...[
            const SizedBox(height: 20),
            _SectionLabel(text: l10n.events_organizerSection, isLight: isLight),
            const SizedBox(height: 8),
            Text(
              details!.organizer!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLight ? const Color(0xFF555566) : AppColors.textDisabled,
              ),
            ),
          ],

          // Open in browser
          if (event.link != null) ...[
            const SizedBox(height: 32),
            _OpenBrowserButton(onTap: onOpenBrowser),
          ],

          SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block, bool isLight) {
    final theme = Theme.of(context);
    return switch (block) {
      TextBlock(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLight ? const Color(0xFF555566) : AppColors.textDisabled,
              height: 1.65,
            ),
          ),
        ),
      LinkTextBlock(:final text, :final url) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.link, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AppIcon(AppIcons.chevronRight, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.date,
    required this.time,
    required this.location,
    required this.audience,
    required this.categoryColor,
    required this.isLight,
  });

  final String date;
  final String? time;
  final String? location;
  final String? audience;
  final Color categoryColor;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final rows = <(AppIconData, String, Color)>[];
    if (date.isNotEmpty) rows.add((AppIcons.calendar, date, categoryColor));
    if (time != null && !date.contains(time!)) rows.add((AppIcons.time, time!, categoryColor));
    if (location != null) rows.add((AppIcons.location, location!, const Color(0xFF10B981)));
    if (audience != null) rows.add((AppIcons.users, audience!, const Color(0xFF6366F1)));
    if (rows.isEmpty) return const SizedBox.shrink();

    final bg = isLight ? const Color(0xFFF5F5FA) : const Color(0xFF2C2C3A);
    final div = isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _InfoRow(
              icon: rows[i].$1,
              text: rows[i].$2,
              color: rows[i].$3,
              isLight: isLight,
            ),
            if (i < rows.length - 1)
              Divider(height: 1, indent: 64, color: div),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.isLight,
  });

  final AppIconData icon;
  final String text;
  final Color color;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: AppIcon(icon, size: 18, color: color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isLight ? const Color(0xFF1A1A2E) : AppColors.textColorDark,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category, required this.color});
  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.isLight});
  final String text;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: isLight ? const Color(0xFF0F0F1A) : AppColors.textColorDark,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _OpenBrowserButton extends StatelessWidget {
  const _OpenBrowserButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.events_openInBrowser,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon(AppIcons.openInNew, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.isLight});
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final base = isLight ? const Color(0xFFEEEEF4) : const Color(0xFF3A3A4A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Slab(w: 90, h: 26, r: 20, c: base),
          const SizedBox(height: 14),
          _Slab(w: double.infinity, h: 28, r: 8, c: base),
          const SizedBox(height: 8),
          _Slab(w: 220, h: 28, r: 8, c: base),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF5F5FA) : const Color(0xFF2C2C3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _shimRow(base),
                const SizedBox(height: 14),
                _shimRow(base),
                const SizedBox(height: 14),
                _shimRow(base),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _Slab(w: 120, h: 18, r: 6, c: base),
          const SizedBox(height: 12),
          _Slab(w: double.infinity, h: 14, r: 4, c: base),
          const SizedBox(height: 6),
          _Slab(w: double.infinity, h: 14, r: 4, c: base),
          const SizedBox(height: 6),
          _Slab(w: 180, h: 14, r: 4, c: base),
        ],
      ),
    );
  }

  Widget _shimRow(Color base) => Row(
        children: [
          _Slab(w: 36, h: 36, r: 10, c: base),
          const SizedBox(width: 14),
          Expanded(child: _Slab(w: double.infinity, h: 16, r: 4, c: base)),
        ],
      );
}

class _Slab extends StatelessWidget {
  const _Slab({required this.w, required this.h, required this.r, required this.c});
  final double w;
  final double h;
  final double r;
  final Color c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating circle button (back / external link)
// ─────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final AppIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        child: Center(child: AppIcon(icon, size: 20, color: Colors.white)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category → color map (shared with listing cards)
// ─────────────────────────────────────────────────────────────────────────────

Color _categoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'conferences':          return const Color(0xFF3B82F6);
    case 'seminar':              return const Color(0xFF8B5CF6);
    case 'workshop':             return const Color(0xFFF59E0B);
    case 'guest lecture':        return const Color(0xFF10B981);
    case 'student activity':     return const Color(0xFFEC4899);
    case 'webinar':              return const Color(0xFF6366F1);
    case 'educational program':  return const Color(0xFF14B8A6);
    case 'public talk':          return const Color(0xFFEF4444);
    default:                     return AppColors.primary;
  }
}
