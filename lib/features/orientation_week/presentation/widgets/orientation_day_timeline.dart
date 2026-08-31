import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../config/orientation_links.dart';
import '../../domain/entities/orientation_schedule.dart';
import 'schedule_session_row.dart' show scheduleImportanceAccent;

/// One session, laid out on the hour grid: which column of however many are
/// overlapping it at that moment, and how many columns that cluster needs.
class _TimelineSlot {
  const _TimelineSlot({required this.session, required this.column, required this.columns});

  final ScheduleSession session;
  final int column;
  final int columns;
}

/// Greedy interval-graph colouring — the same shape Apple/Google Calendar use
/// for a day with overlapping meetings: events that overlap in time sit in
/// side-by-side columns instead of stacking on top of each other, and events
/// that don't overlap anything share the full width.
///
/// Sessions are pre-sorted by start time. A running cluster absorbs every
/// session whose start falls before the cluster's current latest end; once a
/// session starts after that, the cluster is closed and columns are assigned
/// to it in isolation, so two clusters hours apart never fight over column
/// count.
List<_TimelineSlot> _layout(List<ScheduleSession> sessions) {
  final sorted = [...sessions]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  final result = <_TimelineSlot>[];

  var i = 0;
  while (i < sorted.length) {
    var clusterEnd = sorted[i].endMinutes;
    var j = i + 1;
    while (j < sorted.length && sorted[j].startMinutes < clusterEnd) {
      if (sorted[j].endMinutes > clusterEnd) clusterEnd = sorted[j].endMinutes;
      j++;
    }

    final cluster = sorted.sublist(i, j);
    final columnEnds = <int>[];
    final columnOf = <int>[];
    for (final session in cluster) {
      var placed = -1;
      for (var c = 0; c < columnEnds.length; c++) {
        if (columnEnds[c] <= session.startMinutes) {
          columnEnds[c] = session.endMinutes;
          placed = c;
          break;
        }
      }
      if (placed == -1) {
        columnEnds.add(session.endMinutes);
        placed = columnEnds.length - 1;
      }
      columnOf.add(placed);
    }

    for (var k = 0; k < cluster.length; k++) {
      result.add(_TimelineSlot(session: cluster[k], column: columnOf[k], columns: columnEnds.length));
    }
    i = j;
  }

  return result;
}

/// A day, drawn as a full 24-hour grid with session blocks positioned by time
/// — the Apple/Google Calendar day view.
///
/// Every day uses the *same* midnight-to-midnight scale rather than one
/// stretched between that day's own first and last session: five days on five
/// different scales would make an hour look like a different height depending
/// on which day happened to be open, and a grid cropped to the first and last
/// session clips their own labels at the very edges it is drawn to.
///
/// The grid is taller than a phone screen, so it scrolls inside its own fixed
/// viewport rather than lengthening the page — opened already scrolled to
/// [_defaultStartHour], since every session in this timetable falls at or
/// after 8am and a calendar that opens on an empty midnight is a calendar you
/// have to scroll before you can read it.
class OrientationDayTimeline extends StatefulWidget {
  const OrientationDayTimeline({super.key, required this.day});

  final ScheduleDay day;

  @override
  State<OrientationDayTimeline> createState() => _OrientationDayTimelineState();
}

class _OrientationDayTimelineState extends State<OrientationDayTimeline> {
  static const double _hourHeight = 64;
  static const double _hourLabelWidth = 44;
  static const double _minEventHeight = 40;
  static const int _defaultStartHour = 8;

  /// Space above midnight and below the following midnight so the 00:00 and
  /// 24:00 labels have somewhere to sit — without it, a label centred exactly
  /// on the grid's own top or bottom edge is half clipped by the scroll
  /// view's own bounds.
  static const double _labelPad = 12;

  late final ScrollController _controller = ScrollController(
    initialScrollOffset: _defaultStartHour * _hourHeight,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _yFor(int minutes) => _labelPad + minutes / 60 * _hourHeight;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = widget.day.date.year == now.year &&
        widget.day.date.month == now.month &&
        widget.day.date.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;
    final slots = _layout(widget.day.sessions);
    const contentHeight = 24 * _hourHeight + _labelPad * 2;

    return Container(
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          padding: const EdgeInsets.symmetric(vertical: FeatureStyle.s8),
          child: SizedBox(
            height: contentHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final blockAreaWidth = constraints.maxWidth - _hourLabelWidth - FeatureStyle.s8 - FeatureStyle.s12;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Hour gridlines and labels — every hour, midnight to
                    // midnight, so all five days share one scale.
                    for (var hour = 0; hour <= 24; hour++)
                      Positioned(
                        top: _yFor(hour * 60) - 7,
                        left: FeatureStyle.s12,
                        right: FeatureStyle.s8,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _hourLabelWidth,
                              child: Text(
                                '${(hour % 24).toString().padLeft(2, '0')}:00',
                                style: FeatureStyle.tiny.copyWith(
                                  fontSize: 10,
                                  fontFeatures: FeatureStyle.tabular,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(height: 1, color: FeatureStyle.hairline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Session blocks — each takes an equal share of
                    // [blockAreaWidth] within its overlap cluster, positioned
                    // by its column index.
                    for (final slot in slots)
                      Positioned(
                        top: _yFor(slot.session.startMinutes),
                        left: FeatureStyle.s12 +
                            _hourLabelWidth +
                            FeatureStyle.s8 +
                            slot.column * (blockAreaWidth / slot.columns),
                        width: blockAreaWidth / slot.columns,
                        height: (_yFor(slot.session.endMinutes) - _yFor(slot.session.startMinutes))
                            .clamp(_minEventHeight, double.infinity),
                        child: _TimelineBlock(session: slot.session),
                      ),
                    if (isToday && nowMinutes >= 0 && nowMinutes <= 24 * 60)
                      Positioned(
                        top: _yFor(nowMinutes),
                        left: FeatureStyle.s12 + _hourLabelWidth,
                        right: FeatureStyle.s8,
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                            Expanded(child: Container(height: 1.5, color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  const _TimelineBlock({required this.session});

  final ScheduleSession session;

  @override
  Widget build(BuildContext context) {
    final accent = scheduleImportanceAccent(session.importance);
    final link = session.link;

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(right: 4, bottom: 2),
      decoration: BoxDecoration(
        color: FeatureStyle.chipTint(accent),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            session.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FeatureStyle.tiny.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: FeatureStyle.ink,
              height: 1.2,
            ),
          ),
          if (session.place != null)
            Text(
              session.place!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FeatureStyle.tiny.copyWith(fontSize: 9.5, color: accent, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );

    if (link == null) return content;
    return PressableScale(onTap: () => openOrientationLink(link), child: content);
  }
}
