import 'package:dio/dio.dart';

import '../entities/experience_entity.dart';

/// Abstract repository for Work Experience data.
/// In the future, this will be implemented by a remote data source.
abstract class ExperienceRepository {
  /// Get all experience entries for current user.
  Future<List<ExperienceEntity>> getExperienceList({CancelToken? cancelToken});

  /// Get experience entries by user ID.
  Future<List<ExperienceEntity>> getExperienceByUserId(String userId);

  /// Add a new experience entry.
  Future<ExperienceEntity> addExperience(ExperienceEntity experience);

  /// Update an experience entry.
  Future<ExperienceEntity> updateExperience(ExperienceEntity experience);

  /// Delete an experience entry.
  Future<void> deleteExperience(String id);
}
