import 'package:app_ui/app_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/event.dart';
import '../providers/events_provider.dart';
import 'event_follow_bell.dart';

class EventsSection extends ConsumerStatefulWidget {
  const EventsSection({super.key});

  @override
  ConsumerState<EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends ConsumerState<EventsSection> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 80) {
      ref.read(eventsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(eventsProvider);

    if (listState.isInitialLoading && !listState.hasData) {
      return _buildShimmer(context);
    }

    final events = listState.events;
    if (events == null || events.isEmpty) return const SizedBox.shrink();

    return _buildContent(context, events, listState);
  }

  Widget _buildContent(BuildContext context, List<NuEvent> events, EventsListState listState) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppLocalizations.of(context)!.events_nuTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: events.length + (listState.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == events.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: SizedBox(
                        width: 48,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.only(right: index < events.length - 1 ? 12 : 0),
                    child: _EventCard(event: events[index]),
                  );
                },
              ),
              Positioned(
                right: 0, top: 0, bottom: 0, width: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (isLight ? AppColors.background : AppColors.surfaceDark).withValues(alpha: 0),
                          isLight ? AppColors.background : AppColors.surfaceDark,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight ? Colors.grey.shade200 : Colors.grey.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 100, height: 18,
            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
              child: Container(
                width: 168,
                decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final NuEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    Future<void> openDetails() async {
      final connected = await ConnectivityService.isConnected();
      if (!context.mounted) return;
      if (!connected) {
        AppToast.showError(context, AppLocalizations.of(context)!.profile_errorNetwork);
        return;
      }
      context.push(AppRoutes.eventDetails, extra: event);
    }

    return Container(
      width: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: openDetails,
                    child: event.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: event.imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 340,
                            memCacheHeight: 200,
                            placeholder: (ctx, url) => _imageFallback(event.category),
                            errorWidget: (ctx, url, err) => _imageFallback(event.category),
                          )
                        : _imageFallback(event.category),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: EventFollowBell(
                      event: event,
                      style: EventFollowBellStyle.card,
                    ),
                  ),
                ],
              ),
            ),
            // ── Content ──
            Expanded(
              child: GestureDetector(
                onTap: openDetails,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isLight ? AppColors.textColor : AppColors.textColorDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Date
                      if (event.date.isNotEmpty || event.time != null)
                        _MetaRow(
                          icon: AppIcons.calendar,
                          text: _shortDate(event.date, event.time),
                          isLight: isLight,
                        ),
                      // Venue
                      if (event.venue.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _MetaRow(icon: AppIcons.location, text: event.venue, isLight: isLight),
                      ],
                      // Audience
                      if (event.audience != null) ...[
                        const SizedBox(height: 2),
                        _MetaRow(icon: AppIcons.users, text: event.audience!, isLight: isLight),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(String? category) {
    final color = _categoryColor(category);
    return Container(
      color: color.withValues(alpha: 0.10),
      child: Center(child: AppIcon(AppIcons.calendar, size: 28, color: color)),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, required this.isLight});
  final AppIconData icon;
  final String text;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 11, color: isLight ? AppColors.grey : AppColors.textDisabled),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: isLight ? AppColors.grey : AppColors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }
}

Color _categoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'conferences': return const Color(0xFF3B82F6);
    case 'seminar':     return const Color(0xFF8B5CF6);
    case 'workshop':    return const Color(0xFFF59E0B);
    case 'guest lecture': return const Color(0xFF10B981);
    case 'student activity': return const Color(0xFFEC4899);
    case 'webinar':     return const Color(0xFF6366F1);
    case 'educational program': return const Color(0xFF14B8A6);
    case 'public talk': return const Color(0xFFEF4444);
    default:            return AppColors.primary;
  }
}

String _shortDate(String date, String? time) {
  final cleaned = date.replaceFirst(RegExp(r'^[A-Za-z]{3},\s*'), '');
  if (cleaned.isEmpty && time == null) return '';
  return time != null ? '$cleaned · $time' : cleaned;
}
