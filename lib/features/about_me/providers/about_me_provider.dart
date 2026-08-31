import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/about_me_repository_impl.dart';
import '../domain/entities/about_me_entity.dart';
import '../domain/repositories/about_me_repository.dart';

/// Repository provider for about me data
final aboutMeRepositoryProvider = Provider<AboutMeRepository>((ref) {
  return AboutMeRepositoryImpl();
});

/// Provider for user's about me data
final aboutMeProvider = StateNotifierProvider<AboutMeNotifier, AsyncValue<AboutMeEntity>>((ref) {
  return AboutMeNotifier(ref.watch(aboutMeRepositoryProvider));
});

/// Provider for other user's about me data
final userAboutMeProvider =
    FutureProvider.autoDispose.family<AboutMeEntity, String>((ref, userId) async {
  final repository = ref.watch(aboutMeRepositoryProvider);
  return repository.getAboutMeByUserId(userId);
});

class AboutMeNotifier extends StateNotifier<AsyncValue<AboutMeEntity>> {
  AboutMeNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadAboutMe();
  }

  final AboutMeRepository _repository;

  Future<void> _loadAboutMe() async {
    try {
      final aboutMe = await _repository.getAboutMe();
      state = AsyncValue.data(aboutMe);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateContent(String content) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    try {
      final updated = await _repository.updateAboutMe(
        current.copyWith(content: content, updatedAt: DateTime.now()),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(AboutMeEntity.empty);
  }
}
