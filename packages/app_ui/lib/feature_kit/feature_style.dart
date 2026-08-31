import '../tokens/app_colors.dart';
import 'package:flutter/material.dart';

/// Revolut-flavoured design tokens for the Orientation Week feature.
///
/// One consistent surface language across every screen — deliberately, not
/// a mix: every card is white with a 1px hairline border, `rCard` (20px)
/// radius, and no drop shadow. The single "emphasis" pattern (selected tabs,
/// progress fills, featured cards, CTAs, the balance pill) is always the
/// brand cobalt ([AppColors.primary] `#7100FF`) filled with white text —
/// reused everywhere rather than switching between different accent
/// treatments per widget. Near-black ink type with tight negative tracking
/// and pill buttons round out the look. A narrow 4-colour icon-accent
/// palette ([accentCobalt]/[accentTeal]/[accentOrange]/[accentPink]) is
/// reserved strictly for small icon-chip glyphs inside these white cards —
/// never as a card or button surface — so the feature stays colourful
/// without ever competing with the base white/hairline/cobalt system.
///
/// Only the brand primary and white are taken from [AppColors]; the neutral
/// ladder (ink → stone) is defined here so the feature reads as one
/// deliberate system. Member names are kept stable so every existing surface
/// adopts the language at once.
abstract class FeatureStyle {
  // ── Theme ─────────────────────────────────────────────────────────────────
  //
  // Every neutral below (ink → surfaceSoft, plus the card fill and page
  // background) is read as a bare static property at ~90+ call sites with no
  // BuildContext in reach, so there is no way to thread Theme.of(context)
  // through each of them individually. Instead the app's root MaterialApp
  // builder calls [updateBrightness] on every build (see lib/main.dart),
  // keeping this ambient flag current with the live theme, and every neutral
  // getter below branches on it. Brand/accent colours (accent, accentCobalt,
  // accentTeal, accentOrange, accentPink, and OrientationBrand's ADSL
  // palette) are deliberately NOT part of this — they stay the same hue in
  // both themes, matching how AppTheme.darkTheme keeps its own accent fixed
  // rather than recolouring the light one.
  static Brightness _brightness = Brightness.light;
  static bool get _isDark => _brightness == Brightness.dark;

  /// Public read of the same flag, for the handful of call sites outside
  /// this file (e.g. [FeatureCard]'s default fill) that need to branch on it
  /// directly rather than through one of the neutral getters below.
  static bool get isDark => _isDark;

  /// Called once per build from the app root so every neutral below reflects
  /// the live theme. Safe to call redundantly — it's just a flag write.
  static void updateBrightness(Brightness brightness) => _brightness = brightness;

  // ── Palette ───────────────────────────────────────────────────────────────

  /// The brand accent (cobalt-violet). The loudest stamp — the current-day
  /// node, the progress fill, a featured CTA. Fixed across both themes.
  static const accent = AppColors.primary;

  // ── Accent palette (design.md) ─────────────────────────────────────────────
  // Deliberately narrow — four colours, reused everywhere, rather than a
  // different tint per category. Used ONLY as iconography — icon glyphs over
  // a soft tint of the same colour (`~12%`) — never as button or card
  // surfaces. This is what keeps the feature colourful without reading as a
  // scattered rainbow of one-off tints. Fixed across both themes.
  static const accentCobalt = AppColors.primary; // #7100FF — brand / primary
  static const accentTeal = Color(0xFF00A87E); // explore / campus / study
  static const accentOrange = Color(0xFFEC7E00); // food / effort / reward
  static const accentPink = Color(0xFFE61E49); // social / highlight

  /// Soft chip fill for an accent glyph — the accent at low opacity.
  static Color chipTint(Color accent) => accent.withValues(alpha: 0.12);

  /// Primary heading ink — warmer than pure black, crisp on white in light
  /// mode; near-white on dark surfaces.
  static Color get ink => _isDark ? const Color(0xFFF5F5F5) : const Color(0xFF191C1F);

  /// Long-form body ink.
  static Color get bodyInk => _isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1F2226);

  /// Supporting text. Reuses [AppColors.grey] in dark mode — the same
  /// secondary-text-on-dark-surface tone AppTheme.darkTheme already uses
  /// elsewhere (e.g. the unselected bottom-nav label), so this doesn't
  /// introduce a new grey the rest of the app doesn't already share.
  static Color get mute => _isDark ? AppColors.grey : const Color(0xFF505A63);

  /// Metadata / subtle captions — one step quieter than [mute].
  static Color get stone => _isDark ? const Color(0xFF7A7A7A) : const Color(0xFF8D969E);

  /// 1px dividers and card outlines — matches [AppColors.borderDark] in dark
  /// mode, the same border tone AppTheme.darkTheme's divider/border use.
  static Color get hairline => _isDark ? const Color(0xFF333333) : const Color(0xFFE2E2E7);

  /// Soft inset fill for unselected chips/tabs and progress tracks — one
  /// step lighter than the card surface it usually sits inside.
  static Color get surfaceSoft => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF4F4F4);

  /// The page's own background, behind every card — matches
  /// AppTheme.darkTheme's scaffoldBackgroundColor exactly.
  static Color get pageBackground => _isDark ? const Color(0xFF171717) : AppColors.white;

  /// The standard card fill — matches [FeatureCard]'s own default (it reuses
  /// this getter). Any widget that builds its own `Container` instead of
  /// wrapping in [FeatureCard] (a custom layout that still wants to sit as a
  /// card) should use this instead of hardcoding [AppColors.white] — hardcoded
  /// white stays white in dark mode, which is where the recurring "text is
  /// gone in dark mode" bug comes from: the *text* on top of it still resolves
  /// through [ink]/[bodyInk]/etc., which correctly flips to a light colour in
  /// dark mode, so light-on-hardcoded-white becomes invisible.
  static Color get cardFill => _isDark ? const Color(0xFF242424) : AppColors.white;

  /// White text/icons on a filled [accent] surface (selected tabs, the
  /// balance pill, featured cards, CTAs) — the recurring emphasis pattern.
  /// Always white regardless of theme — it's text on a fixed-colour accent
  /// fill, not a neutral surface.
  static const onDark = Colors.white;

  // ── Radii ─────────────────────────────────────────────────────────────────

  static const double rHero = 24; // storytelling hero cards
  static const double rCard = 20; // feature / catalogue cards
  static const double rChip = 12; // inputs, small chips
  static const double rPill = 100; // buttons, pills, badges

  /// Fixed height shared by every "filter row" control — the Challenges /
  /// Photo Quest segmented tabs and the Rewards category chips — so they
  /// always read as one size regardless of which page they're on.
  static const double filterRowHeight = 40;

  // ── Spacing (strict 4px grid) ─────────────────────────────────────────────
  //
  // Every gap in the feature comes from this ladder. Anything not on it (a
  // stray 14, a 22) is what makes two otherwise-identical sections look
  // subtly misaligned, which is the single most common way a dense mobile
  // layout stops reading as one system.

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Horizontal page gutter, identical on every screen.
  static const double pagePadding = s20;

  /// Vertical gap between two sections.
  static const double sectionGap = s24;

  // ── Component metrics ─────────────────────────────────────────────────────
  //
  // Fixed heights, not content-derived ones. A list of rows that each size to
  // their own copy reads as ragged no matter how good the type is; Revolut's
  // lists hold one height and let long copy truncate or wrap into a reserved
  // slot instead.

  /// A one-line list row (title + trailing value).
  static const double rowHeight = 72;

  /// A list row carrying a two-line description as well.
  static const double rowHeightTall = 92;

  /// Pill CTA height.
  static const double buttonHeight = 52;

  /// The leading icon square inside a row or tile.
  static const double iconChip = 40;

  // ── Numerals ──────────────────────────────────────────────────────────────

  /// Tabular figures, so digits occupy identical width. Balances, token
  /// counts, ranks and countdowns must never jitter as they change — this is
  /// the detail that makes a fintech list feel engineered rather than typed.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  // ── Type scale (family inherited from theme — Geist) ───────────────────────
  //
  // Every style below embeds a theme-aware neutral (ink/bodyInk/mute/stone),
  // so each is a getter rather than a `const` — a `const TextStyle` can't
  // embed a value that isn't itself compile-time constant.

  /// Nav-bar title.
  static TextStyle get navTitle => TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3, height: 1.1);

  /// Centred subtitle lines under the nav bar.
  static TextStyle get subtitle => TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: mute, height: 1.35);

  /// Display — hero numbers and headline titles (tight, editorial).
  static TextStyle get display => TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.7, height: 1.02, fontFeatures: tabular);

  /// The big standalone figure on a stat tile — a token balance, a rank, a
  /// percentage. Tabular so it never reflows as the value changes.
  static TextStyle get metric => TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.6, height: 1.0, fontFeatures: tabular);

  /// A trailing value on a list row ("3 / 5", "+120").
  static TextStyle get rowValue => TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2, height: 1.1, fontFeatures: tabular);

  /// The small all-caps label above a section or over a metric. Revolut uses
  /// these sparingly to label a group without spending a heading on it.
  static TextStyle get overline => TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stone, letterSpacing: 0.6, height: 1.2);

  /// Section header ("Quick Access", "Token Rewards").
  static TextStyle get sectionTitle => TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.4, height: 1.1);

  /// Card titles.
  static TextStyle get cardTitle => TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2, height: 1.15);

  /// Default body — Inter-like, positive tracking for UI precision.
  static TextStyle get body => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: bodyInk, letterSpacing: 0.1, height: 1.45);

  /// Secondary text — descriptions, "View All".
  static TextStyle get secondary => TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mute, height: 1.35);

  /// Captions.
  static TextStyle get caption => TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: stone, height: 1.3);

  /// Tiny helper labels.
  static TextStyle get tiny => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stone, height: 1.2);

  // ── Elevation ──────────────────────────────────────────────────────────────

  /// Revolut has no drop-shadow language — depth comes from the hairline
  /// outline alone. Kept as an (empty) list so existing `boxShadow:` call
  /// sites need no change.
  static const cardShadow = <BoxShadow>[];

  /// Hairline card outline used everywhere on card surfaces.
  static Border get cardBorder => Border.fromBorderSide(BorderSide(color: hairline, width: 1));

  static const animationDuration = Duration(milliseconds: 240);
  static const animationCurve = Curves.easeOutCubic;
}
