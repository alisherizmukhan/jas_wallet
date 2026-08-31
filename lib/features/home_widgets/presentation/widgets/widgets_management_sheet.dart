import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_widget_item.dart';
import '../providers/home_widgets_provider.dart';

/// Bottom sheet for managing home page widgets visibility and order
class WidgetsManagementSheet extends ConsumerStatefulWidget {
  const WidgetsManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WidgetsManagementSheet(),
    );
  }

  @override
  ConsumerState<WidgetsManagementSheet> createState() =>
      _WidgetsManagementSheetState();
}

class _WidgetsManagementSheetState
    extends ConsumerState<WidgetsManagementSheet> {
  // Measured after first render so the drag ghost is clipped to the exact
  // tile height, hiding the bottom margin from the proxy widget.
  double _tileHeight = 72.0;
  final GlobalKey _tileKey = GlobalKey();
  bool _measured = false;

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _measured) return;
      final box =
          _tileKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.height > 0) {
        _measured = true;
        // Container has margin(bottom:8) so subtract it to get visual height.
        final h = box.size.height - 8;
        if ((h - _tileHeight).abs() > 0.5) {
          setState(() => _tileHeight = h);
        }
      } else {
        _scheduleMeasure();
      }
    });
  }

  String _getWidgetLocalizedName(String id, AppLocalizations l10n) {
    switch (id) {
      case HomeWidgetIds.stories:   return l10n.hub_stories;
      case HomeWidgetIds.saltoCard: return l10n.hub_saltoCard;
      case HomeWidgetIds.events:    return l10n.hub_events;
      case HomeWidgetIds.weather:   return l10n.hub_weather;
      case HomeWidgetIds.exchange:  return l10n.hub_exchange;
      default:                      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetsAsync = ref.watch(homeWidgetsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                l10n.widgets_title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.widgets_description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Widgets list
          Expanded(
            child: widgetsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text(l10n.profile_errorGeneric)),
              data: (widgets) {
                const supported = {
                  HomeWidgetIds.stories,
                  HomeWidgetIds.saltoCard,
                  HomeWidgetIds.events,
                  HomeWidgetIds.weather,
                  HomeWidgetIds.exchange,
                };
                final topLevel = widgets
                    .where((w) => supported.contains(w.id))
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));

                if (!_measured) _scheduleMeasure();

                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  proxyDecorator: (child, index, animation) {
                    // Flutter's drag proxy uses Positioned without a height
                    // constraint, so LayoutBuilder would get Infinity.
                    // Use the measured _tileHeight with ClipRect to show only
                    // the tile, hiding the 8 px bottom margin.
                    return SizedBox(
                      height: _tileHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: OverflowBox(
                          maxHeight: double.infinity,
                          alignment: Alignment.topCenter,
                          child: Material(
                            elevation: 6,
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            shadowColor: Colors.black26,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: topLevel.length,
                  onReorder: (oldIndex, newIndex) {
                    // Stories (index 0) is always locked at the top.
                    if (oldIndex == 0) return;
                    var adjusted = newIndex;
                    if (oldIndex < adjusted) adjusted--;
                    if (adjusted <= 0) adjusted = 1;
                    if (adjusted == oldIndex) return;
                    ref
                        .read(homeWidgetsProvider.notifier)
                        .reorderTopLevel(oldIndex, adjusted);
                  },
                  itemBuilder: (context, index) {
                    final w = topLevel[index];
                    final locked = w.id == HomeWidgetIds.stories;
                    return Padding(
                      key: ValueKey(w.id),
                      padding: EdgeInsets.zero,
                      child: _WidgetListTile(
                        key: (!_measured && index == 0) ? _tileKey : null,
                        widget: w,
                        displayName: _getWidgetLocalizedName(w.id, l10n),
                        isLocked: locked,
                        showDragHandle: !locked,
                        index: index,
                        onToggle: locked
                            ? null
                            : () => ref
                                .read(homeWidgetsProvider.notifier)
                                .toggleVisibility(w.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
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

/// Individual widget list tile with checkbox and drag handle
class _WidgetListTile extends StatelessWidget {
  const _WidgetListTile({
    super.key,
    required this.widget,
    required this.displayName,
    required this.onToggle,
    this.isLocked = false,
    this.showDragHandle = true,
    this.index = 0,
  });

  final HomeWidgetItem widget;
  final String displayName;
  final VoidCallback? onToggle;
  final bool isLocked;
  final bool showDragHandle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isVisible
              ? theme.colorScheme.primary
              : (isLight ? AppColors.borderGrey : AppColors.borderDark),
          width: widget.isVisible ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: isLocked ? null : onToggle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.isVisible ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isVisible ? AppColors.primary : AppColors.grey,
                width: 2,
              ),
            ),
            child: widget.isVisible
                ? Icon(
                    isLocked ? Icons.lock : Icons.check,
                    size: 16,
                    color: AppColors.white,
                  )
                : null,
          ),
        ),
        title: Row(
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isVisible
                    ? (theme.textTheme.bodyLarge?.color ?? AppColors.textColor)
                    : AppColors.grey,
              ),
            ),
            if (isLocked) ...[
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppLocalizations.of(context)!.widgets_alwaysVisible,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: showDragHandle
            ? ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              )
            : null,
      ),
    );
  }
}
