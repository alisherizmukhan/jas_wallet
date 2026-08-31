/// The shared building blocks every Orientation Week and Club Fair screen is
/// laid out from.
///
/// The point of putting them in one file is that "consistent" stops being a
/// thing each page has to remember and becomes the only thing available: a
/// screen composes [FeatureSection]s of [FeatureCard]s containing
/// [FeatureListRow]s, and it cannot accidentally invent a different card
/// radius, row height, or section gap along the way.
///
/// Modelled on the Revolut app rather than the revolut.com marketing site:
/// flat white sheets, hairline separators, one accent, fixed row heights,
/// tabular figures, pill CTAs — no drop shadows, no gradient surfaces, no
/// dark hero bands.
library;

import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'package:flutter/material.dart';

import 'feature_style.dart';
import 'pressable_scale.dart';

/// The one card container: white, 1px hairline, 20px radius, never a shadow.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Overrides the card's default fill — null keeps the standard flat sheet
  /// every other caller (including Club Fair) relies on (white in light
  /// mode, the dark-surface tone in dark mode). For the rare card that is
  /// meant to read as a tinted surface rather than content on the base
  /// surface, not a second surface language.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    return onTap == null ? card : PressableScale(onTap: onTap!, child: card);
  }
}

/// The feature's "one line that opens onto more" card.
///
/// Four of these exist — What is Orientation Week, In collaboration with
/// ADSL, How to get your prize, Redemption History — and they only read as a
/// set because they are literally the same object: one 36px glyph, one title,
/// one trailing affordance, at one fixed [headerHeight]. Two of them unfold
/// ([body]); two of them lead somewhere ([onTap]). Sizing each by its own
/// content is what previously made four sibling cards land at four different
/// heights on two different screens.
class FeatureHeaderCard extends StatelessWidget {
  const FeatureHeaderCard({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.accent = FeatureStyle.accentCobalt,
    this.body,
    this.collapsed = true,
    this.onToggle,
    this.onTap,
    this.trailing,
    this.backgroundColor,
  }) : assert(body == null || onTap == null,
            'a card either unfolds or navigates — never both');

  final String title;

  /// Leading glyph, shown in an [accent]-tinted chip.
  final AppIconData? icon;

  /// Replaces the glyph chip outright (a partner's logo). Sized by the caller
  /// to [chipSize] so the four cards keep one left column.
  final Widget? leading;

  final Color accent;

  /// Forwarded to the underlying [FeatureCard] — see its own doc.
  final Color? backgroundColor;

  /// What unfolds below the header. Null makes this a navigational card.
  final Widget? body;
  final bool collapsed;
  final VoidCallback? onToggle;

  /// Where the card leads. Null (with [body] set) makes it a folding card.
  final VoidCallback? onTap;

  /// Extra affordance before the chevron — a partner's mark, a count.
  final Widget? trailing;

  /// Every one of these cards is exactly this tall when folded.
  static const double headerHeight = 64;
  static const double chipSize = 36;

  @override
  Widget build(BuildContext context) {
    final header = SizedBox(
      height: headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(FeatureStyle.s16, 0, 14, 0),
        child: Row(
          children: [
            leading ??
                Container(
                  width: chipSize,
                  height: chipSize,
                  decoration: BoxDecoration(
                    color: FeatureStyle.chipTint(accent),
                    borderRadius: BorderRadius.circular(FeatureStyle.rChip),
                  ),
                  child: Center(child: AppIcon(icon!, size: 19, color: accent)),
                ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FeatureStyle.cardTitle.copyWith(fontSize: 16),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: FeatureStyle.s8),
              trailing!,
            ],
            const SizedBox(width: FeatureStyle.s8),
            if (body != null)
              AnimatedRotation(
                turns: collapsed ? 0 : 0.5,
                duration: FeatureStyle.animationDuration,
                child: AppIcon(AppIcons.chevronDown, size: 20, color: FeatureStyle.stone),
              )
            else
              AppIcon(AppIcons.chevronRight, size: 20, color: FeatureStyle.stone),
          ],
        ),
      ),
    );

    return FeatureCard(
      backgroundColor: backgroundColor,
      child: Column(
        // Shrink-wrap explicitly. These cards live in a scroll view, where a
        // Column sizes to its children either way — but one dropped into a
        // bounded box would otherwise stretch to fill it, and "all four are
        // the same height" would quietly stop being true.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressableScale(onTap: onTap ?? onToggle ?? () {}, child: header),
          if (body != null)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FeatureStyle.s16,
                  0,
                  FeatureStyle.s16,
                  FeatureStyle.s16,
                ),
                child: body!,
              ),
              crossFadeState: collapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: FeatureStyle.animationDuration,
              sizeCurve: FeatureStyle.animationCurve,
            ),
        ],
      ),
    );
  }
}

/// A titled block of content with the feature's standard header treatment and
/// spacing. [action] renders as the cobalt "View all ›" affordance on the
/// trailing edge.
class FeatureSection extends StatelessWidget {
  const FeatureSection({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.overline,
    this.accentColor,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional small all-caps kicker above the title.
  final String? overline;

  /// Overrides the shared [FeatureStyle.accent] on the action label/chevron —
  /// null keeps the default (used by every caller that doesn't opt in, e.g.
  /// Club Fair).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (overline != null) ...[
                    Text(overline!.toUpperCase(), style: FeatureStyle.overline),
                    const SizedBox(height: FeatureStyle.s4),
                  ],
                  Text(
                    title,
                    // Section headings wrap rather than truncate — a heading
                    // is the one string a reader can least afford to lose.
                    maxLines: 2,
                    style: FeatureStyle.sectionTitle,
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: FeatureStyle.s12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: FeatureStyle.secondary
                            .copyWith(color: accentColor ?? FeatureStyle.accent, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 2),
                      AppIcon(AppIcons.chevronRight, size: 16, color: accentColor ?? FeatureStyle.accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: FeatureStyle.s12),
        child,
      ],
    );
  }
}

/// The list row used across the whole feature — challenges, missions,
/// rewards, leaderboard entries, history entries.
///
/// Uniform by *minimum* height, not fixed height. Every row shares the same
/// floor, so a list reads as one rhythm and the icons down the left edge stay
/// on a single column — but a row whose copy genuinely needs more space grows
/// instead of hiding the overflow behind an ellipsis. Truncation is a
/// last-resort safety net here, not the normal outcome.
class FeatureListRow extends StatelessWidget {
  const FeatureListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.value,
    this.footer,
    this.showChevron = true,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// Leading glyph, rendered in an [iconColor]-tinted chip.
  final AppIconData? icon;
  final Color? iconColor;

  /// Replaces the icon chip entirely (an avatar, a rank badge, a thumbnail).
  final Widget? leading;

  /// Custom trailing widget. Takes precedence over [value].
  final Widget? trailing;

  /// Trailing figure, set in tabular numerals.
  final String? value;

  /// Rendered under the text column — a progress bar, a meta line. Gives a
  /// row structure without spending a decorative icon on it.
  final Widget? footer;

  final bool showChevron;
  final VoidCallback? onTap;

  bool get _isTall => subtitle != null;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? FeatureStyle.accent;

    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: _isTall ? FeatureStyle.rowHeightTall : FeatureStyle.rowHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FeatureStyle.s16,
          // Breathing room for a row that has grown past the minimum.
          vertical: FeatureStyle.s12,
        ),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (icon != null)
              Container(
                width: FeatureStyle.iconChip,
                height: FeatureStyle.iconChip,
                decoration: BoxDecoration(
                  color: FeatureStyle.chipTint(accent),
                  borderRadius: BorderRadius.circular(FeatureStyle.rChip),
                ),
                child: Center(child: AppIcon(icon!, size: 20, color: accent)),
              ),
            if (leading != null || icon != null) const SizedBox(width: FeatureStyle.s12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FeatureStyle.cardTitle,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      // Generous enough that real copy lands inside it; the
                      // row grows to hold whatever it needs.
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w400, height: 1.3),
                    ),
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: FeatureStyle.s8),
                    footer!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: FeatureStyle.s8),
              trailing!,
            ] else if (value != null) ...[
              const SizedBox(width: FeatureStyle.s8),
              Text(value!, style: FeatureStyle.rowValue),
            ],
            if (showChevron) ...[
              const SizedBox(width: FeatureStyle.s4),
              AppIcon(AppIcons.chevronRight, size: 18, color: FeatureStyle.stone),
            ],
          ],
        ),
      ),
    );

    return onTap == null ? row : PressableScale(onTap: onTap!, child: row);
  }
}

/// A thin progress track — the feature's one progress treatment, cobalt fill
/// on a soft grey rail. Used as an [FeatureListRow.footer] to give a
/// multi-step row visible shape without a decorative icon.
class FeatureProgressBar extends StatelessWidget {
  const FeatureProgressBar({super.key, required this.value, this.height = 5, this.color});

  /// 0..1. Clamped, so bad data can't paint outside the track.
  final double value;
  final double height;

  /// Fill colour. Defaults to the one accent — pass another only where the
  /// bar's colour carries meaning the label doesn't (a completed mission's
  /// teal, an achievement tier).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: FeatureStyle.surfaceSoft,
        valueColor: AlwaysStoppedAnimation(color ?? FeatureStyle.accent),
      ),
    );
  }
}

/// Stacks rows inside one [FeatureCard] with hairline separators between
/// them — the grouped-list pattern the whole feature uses instead of a
/// separate card per item.
class FeatureRowGroup extends StatelessWidget {
  const FeatureRowGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return FeatureCard(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                // Inset to the card's own gutter, which reads correctly
                // whether or not the rows carry a leading icon. (Clearing the
                // icon chip instead only looks deliberate when every row has
                // one — it reads as a mistake the moment one doesn't.)
                indent: FeatureStyle.s16,
                endIndent: FeatureStyle.s16,
                color: FeatureStyle.hairline,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single big figure with a label — the unit the summary strips are built
/// from. Equal width by construction when laid out in a [Row] of [Expanded]s.
class FeatureStatTile extends StatelessWidget {
  const FeatureStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent,
  });

  final String value;
  final String label;
  final AppIconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? FeatureStyle.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: 18, color: tint),
          const SizedBox(height: FeatureStyle.s8),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: FeatureStyle.metric),
        ),
        const SizedBox(height: FeatureStyle.s4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w500, height: 1.25),
        ),
      ],
    );
  }
}

/// How much weight a [FeatureCtaButton] carries.
enum FeatureCtaStyle {
  /// Cobalt fill, white type — the feature's single emphasis treatment. One
  /// per screen or sheet.
  filled,

  /// Cobalt hairline on white — an alternative action of equal importance.
  outlined,

  /// Type only, no container — dismiss/cancel, which must never compete with
  /// the action beside it.
  quiet,
}

/// The pill button. Every button in Orientation Week is one of these, so a
/// "Mark as Complete" in the Bingo sheet and a "Redeem" in the reward flow
/// are the same object at the same height rather than two lookalikes built
/// from different primitives.
class FeatureCtaButton extends StatelessWidget {
  const FeatureCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.style = FeatureCtaStyle.filled,
    this.isLoading = false,
    this.fullWidth = true,
    this.accent,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onTap;
  final AppIconData? icon;
  final FeatureCtaStyle style;
  final bool isLoading;

  /// Overrides the shared [FeatureStyle.accent] emphasis colour for this
  /// button only — null keeps the default (used by every caller that
  /// doesn't opt in, e.g. Club Fair).
  final Color? accent;

  /// Stretches to the available width (the default — right for a page's
  /// primary action).
  ///
  /// Set false inside a detail sheet, where the button sits alongside
  /// content-sized status pills ("Completed", "Tracked automatically") and a
  /// full-bleed bar would tower over them. The compact form doesn't just
  /// shrink-wrap: it also drops to [_compactHeight] and lighter padding so a
  /// long label like "Mark as Complete" reads as a sibling of those pills
  /// rather than as a different class of control.
  final bool fullWidth;

  /// Matches the status-pill height used in the detail sheets.
  static const double _compactHeight = 40;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    final isFilled = style == FeatureCtaStyle.filled;
    final resolvedAccent = accent ?? FeatureStyle.accent;

    final ink = switch (style) {
      FeatureCtaStyle.filled => FeatureStyle.onDark,
      FeatureCtaStyle.outlined || FeatureCtaStyle.quiet => resolvedAccent,
    };
    final effectiveInk = enabled ? ink : FeatureStyle.stone;

    final background = switch (style) {
      FeatureCtaStyle.filled =>
        enabled ? resolvedAccent : FeatureStyle.surfaceSoft,
      FeatureCtaStyle.outlined || FeatureCtaStyle.quiet => Colors.transparent,
    };

    final content = Container(
      height: fullWidth ? FeatureStyle.buttonHeight : _compactHeight,
      padding: fullWidth
          ? null
          : const EdgeInsets.symmetric(horizontal: FeatureStyle.s16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        border: style == FeatureCtaStyle.outlined
            ? Border.all(color: enabled ? resolvedAccent : FeatureStyle.hairline)
            : null,
      ),
      child: Center(
        widthFactor: fullWidth ? null : 1,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFilled ? FeatureStyle.onDark : resolvedAccent,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    AppIcon(icon!, size: 18, color: effectiveInk),
                    const SizedBox(width: FeatureStyle.s8),
                  ],
                  // Flexible only when there is a width to be flexible in —
                  // inside a shrink-wrapped Center it would force zero.
                  _MaybeFlexible(
                    flexible: fullWidth,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FeatureStyle.cardTitle.copyWith(color: effectiveInk),
                    ),
                  ),
                ],
              ),
      ),
    );

    final button = enabled ? PressableScale(onTap: onTap!, child: content) : content;
    // A shrink-wrapped button centres itself in whatever the parent gives it,
    // rather than pinning to the leading edge.
    return fullWidth ? button : Center(child: button);
  }
}

/// Wraps [child] in a [Flexible] only when it makes sense to — a `Flexible`
/// inside a shrink-wrapping parent collapses to nothing.
class _MaybeFlexible extends StatelessWidget {
  const _MaybeFlexible({required this.flexible, required this.child});

  final bool flexible;
  final Widget child;

  @override
  Widget build(BuildContext context) => flexible ? Flexible(child: child) : child;
}

/// The standard page scroll container — identical gutters and rhythm on every
/// screen, with [sectionGap] applied between children automatically.
class FeaturePageBody extends StatelessWidget {
  const FeaturePageBody({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FeatureStyle.pagePadding,
        FeatureStyle.s12,
        FeatureStyle.pagePadding,
        FeatureStyle.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: FeatureStyle.sectionGap),
            children[i],
          ],
        ],
      ),
    );
  }
}
