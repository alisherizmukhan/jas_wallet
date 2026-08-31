import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_repository_provider.dart';
import '../data/repositories/social_meal_repository_impl.dart';

final socialMealRepositoryProvider = Provider<SocialMealRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialMealRepositoryImpl(apiClient: apiClient);
});
