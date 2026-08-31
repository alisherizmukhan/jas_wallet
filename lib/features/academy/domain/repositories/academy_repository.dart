import 'package:dio/dio.dart';

import '../entities/academy_entity.dart';

/// Abstract repository for Academy/Education data.
/// In the future, this will be implemented by a remote data source.
abstract class AcademyRepository {
  /// Get all education entries for current user.
  Future<List<AcademyEntity>> getAcademyList({CancelToken? cancelToken});

  /// Get education entries by user ID.
  Future<List<AcademyEntity>> getAcademyByUserId(String userId);

  /// Add a new education entry.
  Future<AcademyEntity> addAcademy(AcademyEntity academy);

  /// Update an education entry.
  Future<AcademyEntity> updateAcademy(AcademyEntity academy);

  /// Delete an education entry.
  Future<void> deleteAcademy(String id);
}
