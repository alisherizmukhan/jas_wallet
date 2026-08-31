import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// FAQ section for the SVC Meal dashboard.
/// Covers the new default-attendance + cancellation + streak model.
class SVCFaqSection extends StatelessWidget {
  const SVCFaqSection({
    required this.theme,
    required this.l10n,
    super.key,
  });

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final items = [
      (AppIcons.close, l10n.svc_faqCancelQ, l10n.svc_faqCancelA),
      (AppIcons.warning, l10n.svc_faqNoShowQ, l10n.svc_faqNoShowA),
      (AppIcons.flame, l10n.svc_faqStreakQ, l10n.svc_faqStreakA),
      (AppIcons.qrCode, l10n.svc_faqQrQ, l10n.svc_faqQrA),
      (AppIcons.time, l10n.svc_faqDeadlineQ, l10n.svc_faqDeadlineA),
      (AppIcons.back, l10n.svc_faqUndoQ, l10n.svc_faqUndoA),
    ];

    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.svc_faq,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _FaqItem(
                  icon: items[i].$1,
                  question: items[i].$2,
                  answer: items[i].$3,
                  theme: theme,
                  isDark: isDark,
                  isFirst: i == 0,
                  isLast: i == items.length - 1,
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.icon,
    required this.question,
    required this.answer,
    required this.theme,
    required this.isDark,
    required this.isFirst,
    required this.isLast,
  });

  final AppIconData icon;
  final String question;
  final String answer;
  final ThemeData theme;
  final bool isDark;
  final bool isFirst;
  final bool isLast;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: widget.isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: widget.isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(
                      widget.icon,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: AppIcon(
                        AppIcons.chevronDown,
                        size: 20,
                        color: AppColors.grey.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10, left: 30),
                          child: AnimatedOpacity(
                            opacity: _expanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              widget.answer,
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.grey,
                                height: 1.6,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
