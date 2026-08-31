import 'package:flutter/material.dart';
import 'onboarding_content.dart';

/// Helper to get onboarding content based on locale
class OnboardingContentHelper {
  /// Get onboarding pages for the current locale
  static List<OnboardingPage> getPages(BuildContext context) {
    final locale = Localizations.localeOf(context);
    
    switch (locale.languageCode) {
      case 'ru':
        return OnboardingContentRu.pages;
      case 'kk':
        return OnboardingContentKk.pages;
      case 'en':
      default:
        return OnboardingContentEn.pages;
    }
  }

  /// Get a specific onboarding page
  static OnboardingPage? getPage(BuildContext context, int pageIndex) {
    final pages = getPages(context);
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pages[pageIndex];
  }
}
