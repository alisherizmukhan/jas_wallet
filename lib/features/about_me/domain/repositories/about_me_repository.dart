import '../entities/about_me_entity.dart';

/// Abstract repository for About Me data.
/// In the future, this will be implemented by a remote data source.
abstract class AboutMeRepository {
  /// Get current user's about me.
  Future<AboutMeEntity> getAboutMe();

  /// Get about me by user ID.
  Future<AboutMeEntity> getAboutMeByUserId(String userId);

  /// Update about me content.
  Future<AboutMeEntity> updateAboutMe(AboutMeEntity aboutMe);
}
