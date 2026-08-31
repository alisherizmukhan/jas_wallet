import '../entities/user_entity.dart';
import '../entities/user_stats_entity.dart';

/// Abstract repository for user data.
/// In the future, this will be implemented by a remote data source.
abstract class UserRepository {
  /// Get user from in-memory/secure local cache only (no network call).
  Future<UserEntity?> getCachedCurrentUser();

  /// Get current authenticated user.
  Future<UserEntity?> getCurrentUser();

  /// Fetch current authenticated user from backend and update cache.
  Future<UserEntity?> refreshCurrentUser();

  /// Get user by ID.
  Future<UserEntity?> getUserById(String id);

  /// Update user profile.
  Future<UserEntity> updateUser(UserEntity user);

  /// Upload an avatar file for the current user.
  Future<UserEntity> uploadAvatar(String filePath);

  /// Delete the current user's avatar.
  Future<UserEntity> deleteAvatar();

  /// Get user statistics.
  Future<UserStatsEntity> getUserStats();

  /// Update user statistics.
  Future<UserStatsEntity> updateUserStats(UserStatsEntity stats);

  /// Delete user account.
  Future<void> deleteAccount();

  /// Clear in-memory user cache bound to previous auth session.
  void clearCache();
}
