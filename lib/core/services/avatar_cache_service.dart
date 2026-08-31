// ignore_for_file: empty_catches
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching user avatar images to disk for offline access.
///
/// Stores avatar images in the app's cache directory and provides
/// fast retrieval for offline use.
class AvatarCacheService {
  AvatarCacheService();

  static const _avatarDirName = 'avatars';
  static const _currentAvatarFileName = 'current_user_avatar';

  /// Pref key remembering which URL the cached file was downloaded from.
  /// Lets us skip the download entirely when the avatar hasn't changed —
  /// previously EVERY `/students/me` response re-downloaded the same image.
  static const _sourceUrlPrefKey = 'avatar_cache_source_url';
  
  Directory? _cacheDir;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  /// In-flight cache operations to prevent duplicate downloads. Static so
  /// the dedup guarantee holds across every instantiation site (this class
  /// has no DI-enforced singleton), not just within one instance.
  static final Map<String, Future<String?>> _inFlightOps = {};

  /// Get the avatar cache directory, creating it if necessary.
  Future<Directory> _getAvatarDir() async {
    if (_cacheDir != null) return _cacheDir!;
    
    final appCacheDir = await getApplicationCacheDirectory();
    final avatarDir = Directory('${appCacheDir.path}/$_avatarDirName');
    
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    
    _cacheDir = avatarDir;
    return avatarDir;
  }

  /// Get the file path for the current user's cached avatar.
  Future<File> _getCurrentAvatarFile() async {
    final dir = await _getAvatarDir();
    return File('${dir.path}/$_currentAvatarFileName');
  }

  /// Cache the current user's avatar from a URL.
  /// Returns the local file path if successful, null otherwise.
  Future<String?> cacheAvatarFromUrl(String url) async {
    if (url.isEmpty) return null;
    
    // Don't cache asset paths or data URIs
    if (url.startsWith('assets/') || url.startsWith('data:')) {
      return null;
    }
    
    // Only cache HTTP(S) URLs
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }

    // Prevent duplicate concurrent downloads of same URL
    final inFlight = _inFlightOps[url];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _doCacheAvatar(url);
    _inFlightOps[url] = future;
    
    try {
      return await future;
    } finally {
      _inFlightOps.remove(url);
    }
  }

  Future<String?> _doCacheAvatar(String url) async {
    try {
      // Same URL already on disk → nothing to download. Avatar changes
      // always produce a new URL (upload returns a fresh filename), so URL
      // identity is a safe freshness check.
      final file = await _getCurrentAvatarFile();
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_sourceUrlPrefKey) == url && await file.exists()) {
        return file.path;
      }

      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null || response.data!.isEmpty) {
        return null;
      }

      await file.writeAsBytes(Uint8List.fromList(response.data!));
      await prefs.setString(_sourceUrlPrefKey, url);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Get the cached avatar file path if it exists.
  /// Returns null if no cached avatar is available.
  Future<String?> getCachedAvatarPath() async {
    try {
      final file = await _getCurrentAvatarFile();
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
    }
    return null;
  }

  /// Check if a cached avatar exists and return the File.
  Future<File?> getCachedAvatarFile() async {
    try {
      final file = await _getCurrentAvatarFile();
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
    }
    return null;
  }

  /// Clear the cached avatar.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sourceUrlPrefKey);
    } catch (e) {
    }
    // Nothing to delete if the cache directory was never accessed.
    if (_cacheDir == null) return;
    try {
      final file = await _getCurrentAvatarFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
    }
  }

  /// Cache avatar in background (fire and forget).
  void cacheAvatarInBackground(String? url) {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    
    // Fire and forget - don't await
    cacheAvatarFromUrl(url);
  }
}
