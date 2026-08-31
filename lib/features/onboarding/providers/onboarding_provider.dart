import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/onboarding_content.dart';

/// Provider for onboarding pages.
/// 
/// Returns all 7 onboarding pages with their content.
/// Content is language-agnostic here; the page content is determined
/// by the locale in the UI layer.
final onboardingPagesProvider = Provider<List<OnboardingPage>>((ref) {
  /// Default to English pages; the consumer will select based on locale
  return OnboardingContentEn.pages;
});

/// Provider to get a specific onboarding page by index
final onboardingPageProvider = Provider.family<OnboardingPage?, int>((ref, pageIndex) {
  final pages = ref.watch(onboardingPagesProvider);
  if (pageIndex < 0 || pageIndex >= pages.length) return null;
  return pages[pageIndex];
});
