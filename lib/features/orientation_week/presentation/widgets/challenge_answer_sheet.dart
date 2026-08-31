import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../config/orientation_links.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../theme/orientation_brand.dart';

/// What the student chose in [showChallengeAnswerSheet].
sealed class ChallengeAnswerChoice {
  const ChallengeAnswerChoice();
}

/// Store [value] as the answer.
class SaveChallengeAnswer extends ChallengeAnswerChoice {
  const SaveChallengeAnswer(this.value);

  final String value;
}

/// Clear the existing answer, reopening the challenge.
class ClearChallengeAnswer extends ChallengeAnswerChoice {
  const ClearChallengeAnswer();
}

/// The typed-answer sheet — a year, a fact, a name, an Instagram handle.
///
/// One sheet for all four kinds rather than four: what changes between them is
/// the prompt, the keyboard and whether the field is one line or several, all
/// of which the challenge already carries. Four near-identical sheets is how
/// four slightly different paddings get into a feature.
///
/// Resolves null if dismissed.
Future<ChallengeAnswerChoice?> showChallengeAnswerSheet(
  BuildContext context,
  OrientationChallenge challenge,
) {
  return AppBottomSheet.show<ChallengeAnswerChoice>(
    context: context,
    title: challenge.title,
    centerTitle: true,
    child: _AnswerSheetContent(challenge: challenge),
  );
}

class _AnswerSheetContent extends StatefulWidget {
  const _AnswerSheetContent({required this.challenge});

  final OrientationChallenge challenge;

  @override
  State<_AnswerSheetContent> createState() => _AnswerSheetContentState();
}

class _AnswerSheetContentState extends State<_AnswerSheetContent> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.challenge.answer ?? '');

  /// Drives the save button's enabled state, so a student never taps Save on
  /// an empty field and gets nothing.
  late bool _hasText = _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final challenge = widget.challenge;

    return Padding(
      padding: EdgeInsets.only(
        left: FeatureStyle.pagePadding,
        right: FeatureStyle.pagePadding,
        // Lifts the field clear of the keyboard — this sheet is the one place
        // in the feature a student types into.
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            challenge.description,
            textAlign: TextAlign.center,
            style: FeatureStyle.secondary,
          ),
          const SizedBox(height: FeatureStyle.s20),
          if (challenge.prompt != null) ...[
            Text(challenge.prompt!.toUpperCase(), style: FeatureStyle.overline),
            const SizedBox(height: FeatureStyle.s8),
          ],
          AppTextField(
            controller: _controller,
            hint: challenge.hint,
            maxLines: challenge.multiline ? 4 : 1,
            autofocus: true,
            keyboardType: challenge.multiline
                ? TextInputType.multiline
                : TextInputType.text,
            textCapitalization: challenge.kind == ChallengeKind.handle
                ? TextCapitalization.none
                : TextCapitalization.sentences,
          ),
          if (challenge.verifyNote != null) ...[
            const SizedBox(height: FeatureStyle.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AppIcon(AppIcons.info, size: 13, color: FeatureStyle.stone),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(challenge.verifyNote!, style: FeatureStyle.tiny.copyWith(
                  fontWeight: FontWeight.w400,
                ))),
              ],
            ),
          ],
          if (challenge.link != null) ...[
            const SizedBox(height: FeatureStyle.s16),
            FeatureCtaButton(accent: OrientationBrand.accent, 
              label: challenge.linkLabel ?? 'Open link',
              icon: orientationLinkIcon(challenge.link!),
              style: FeatureCtaStyle.outlined,
              onTap: () => openOrientationLink(challenge.link!),
            ),
          ],
          const SizedBox(height: FeatureStyle.s20),
          FeatureCtaButton(accent: OrientationBrand.accent, 
            label: l10n.orientation_challenge_save,
            icon: AppIcons.check,
            onTap: _hasText
                ? () => Navigator.of(context).pop(SaveChallengeAnswer(_controller.text))
                : null,
          ),
          // No "clear answer" any more: a paid completion is final on the
          // server. Saving again edits the stored answer without re-paying.
          SizedBox(height: FeatureStyle.s20 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
