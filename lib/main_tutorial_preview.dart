import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jaswallet_app/core/localization/supported_locales.dart';
import 'package:jaswallet_app/features/tutorial/domain/tutorial_content.dart';
import 'package:jaswallet_app/features/tutorial/domain/tutorial_ids.dart';
import 'package:jaswallet_app/features/tutorial/presentation/pages/tutorial_story_page.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Throwaway entrypoint used only to preview/screenshot the tutorial story UI
/// without going through the full auth flow.
void main() {
  runApp(const _TutorialPreviewApp());
}

class _TutorialPreviewApp extends StatelessWidget {
  const _TutorialPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return TutorialStoryPage(
            tutorialId: TutorialIds.svcMeal,
            slides: TutorialContent.svcMeal(l10n),
          );
        },
      ),
    );
  }
}
