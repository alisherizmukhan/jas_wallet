import 'package:dio/dio.dart';

import '../entities/skill_entity.dart';

/// Abstract repository for Skills data.
/// In the future, this will be implemented by a remote data source.
abstract class SkillsRepository {
  /// Get all skills for current user.
  Future<List<SkillEntity>> getUserSkills({CancelToken? cancelToken});

  /// Get skills by user ID.
  Future<List<SkillEntity>> getSkillsByUserId(String userId);

  /// Get all available skills (for selection).
  Future<List<SkillEntity>> getAllAvailableSkills();

  /// Add a skill to user profile.
  Future<void> addSkill(SkillEntity skill);

  /// Remove a skill from user profile.
  Future<void> removeSkill(String id);

  /// Set user skills.
  Future<void> setSkills(List<SkillEntity> skills);
}
