import 'package:flutter/material.dart';
import '../icons/app_icon.dart';
import '../icons/app_icon_data.dart';
import '../tokens/app_colors.dart';

/// 80×80 rounded service tile with a centered icon/image and a label below.
/// Used for hub-style grids of tappable services (and optionally
/// non-interactive "coming soon" placeholders).
///
/// Provide exactly one of [imageAsset] (a raster asset filling the tile
/// edge-to-edge) or [icon] + [iconColor] (a centered glyph).
///
/// Example:
/// ```dart
/// AppServiceTile(
///   title: 'Access',
///   backgroundColor: AppColors.primaryLight,
///   imageAsset: 'assets/icons/salto_icon.webp',
///   onTap: () => context.go('/access'),
/// )
/// ```
class AppServiceTile extends StatelessWidget {
  const AppServiceTile({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.imageAsset,
    this.icon,
    this.iconColor,
    this.onTap,
    this.topRightBadge,
    this.bottomRightTag,
    this.grayscale = false,
  }) : assert(
          imageAsset != null || (icon != null && iconColor != null),
          'Either imageAsset, or both icon and iconColor, must be provided.',
        );

  /// Label shown below the tile.
  final String title;

  /// Tile background color (behind the icon, or visible at the image's
  /// edges if it doesn't perfectly fill the rounded corners).
  final Color backgroundColor;

  /// Raster asset path rendered to fill the tile edge-to-edge.
  final String? imageAsset;

  /// Centered glyph, used instead of [imageAsset].
  final AppIconData? icon;

  /// Color for [icon]. Required when [icon] is provided.
  final Color? iconColor;

  /// Tap callback. When null, the tile is not interactive.
  final VoidCallback? onTap;

  /// Small pill shown top-right, e.g. an unread count.
  final String? topRightBadge;

  /// Small flat tag shown bottom-right, e.g. "Soon".
  final String? bottomRightTag;

  /// Desaturates the icon/image — used for "coming soon" placeholders so
  /// they read as inactive rather than as live, tappable services.
  final bool grayscale;

  static const _tileSize = 80.0;
  static const _borderRadius = 20.0;

  /// Rec. 601 luma weights, replicated across the RGB channels so every
  /// output pixel becomes an equal-channel gray with the source's original
  /// brightness — i.e. a standard grayscale filter.
  static const _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  Widget _maybeGrayscale(Widget child) {
    if (!grayscale) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile = Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _tileSize,
              height: _tileSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(_borderRadius),
                boxShadow: [
                  // Soft ambient shadow tinted to the tile's own color —
                  // the "colored glow beneath the icon" look premium
                  // app-icon-style tiles (App Store, Apple Wallet) use for
                  // a lifted, 3D feel. Scales naturally with each tile's
                  // own pastel background instead of a fixed color.
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.55),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                  // Grounding shadow — keeps the tile readable against any
                  // page background, independent of backgroundColor.
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_borderRadius),
                child: Center(
                  child: _maybeGrayscale(
                    imageAsset != null
                        ? Image.asset(
                            imageAsset!,
                            width: _tileSize,
                            height: _tileSize,
                            fit: BoxFit.cover,
                          )
                        : AppIcon(icon!, size: 36, color: iconColor!),
                  ),
                ),
              ),
            ),
            if (topRightBadge != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    topRightBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (bottomRightTag != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bottomRightTag!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: _tileSize,
          height: 16,
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: onTap == null ? Colors.grey.shade500 : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      tile = GestureDetector(onTap: onTap, child: tile);
    }
    return tile;
  }
}
