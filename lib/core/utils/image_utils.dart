import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

final MemoryImage _emptyAvatarImage = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7YB9kAAAAASUVORK5CYII=',
  ),
);
final Map<String, MemoryImage> _memoryImageCache = {};
final Map<String, NetworkImage> _networkImageCache = {};
final Map<String, AssetImage> _assetImageCache = {};
final Map<String, FileImage> _fileImageCache = {};

/// Path to the current user's cached avatar file (set by AvatarCacheService).
String? _cachedAvatarPath;

/// Set the cached avatar path (called by AvatarCacheService after caching).
void setCachedAvatarPath(String? path) {
  // Evict stale FileImage from Flutter's image cache when the avatar file changes
  if (_cachedAvatarPath != null) {
    final oldImage = _fileImageCache.remove(_cachedAvatarPath!);
    if (oldImage != null) {
      oldImage.evict();
    }
  }
  _cachedAvatarPath = path;
}

/// Get the current cached avatar path.
String? getCachedAvatarPath() => _cachedAvatarPath;

/// Helper function to get the correct ImageProvider based on the image path.
/// Returns AssetImage for local assets (paths starting with 'assets/')
/// Returns FileImage for cached avatar when available (offline support)
/// Returns NetworkImage for HTTP/HTTPS URLs
/// Returns FileImage for local file paths (from camera/gallery picker)
/// Returns transparent image if path is null/empty.
///
/// [cacheWidth], if given (physical pixels — logical size * devicePixelRatio),
/// wraps the result in [ResizeImage] so a large source photo is decoded at
/// the actual display size instead of full resolution. Pass it for
/// small fixed-size avatar slots (nav bars, list rows); omit it for
/// large/unbounded displays (e.g. the SALTO ID card).
ImageProvider getAvatarImageProvider(String? imagePath, {int? cacheWidth}) {
  final provider = _resolveAvatarProvider(imagePath);
  return cacheWidth == null ? provider : ResizeImage(provider, width: cacheWidth);
}

ImageProvider _resolveAvatarProvider(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    // Try cached avatar as fallback
    if (_cachedAvatarPath != null) {
      final file = _existingLocalFile(_cachedAvatarPath!);
      if (file != null) {
        return _fileImageProvider(file.path);
      }
    }
    return _emptyAvatarImage;
  }

  final dataUriImage = _memoryImageFromDataUri(imagePath);
  if (dataUriImage != null) {
    return dataUriImage;
  }

  if (imagePath.startsWith('assets/')) {
    return _assetImageProvider(imagePath);
  }

  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    // For network images, use cached version if available (offline support)
    // The cached file is updated in the background when online
    if (_cachedAvatarPath != null) {
      final cachedFile = _existingLocalFile(_cachedAvatarPath!);
      if (cachedFile != null) {
        return _fileImageProvider(cachedFile.path);
      }
    }
    return _networkImageProvider(imagePath);
  }

  // Check if it's a local file path (from camera/gallery picker)
  if (imagePath.startsWith('/') ||
      imagePath.contains('\\') ||
      imagePath.contains('cache') ||
      imagePath.contains('tmp')) {
    final file = _existingLocalFile(imagePath);
    if (file != null) return _fileImageProvider(file.path);
  }

  // Default to asset image for any other path
  return _assetImageProvider(imagePath);
}

/// Helper function to get image provider for activity/general images
/// Similar to getAvatarImageProvider but without default fallback
///
/// See [getAvatarImageProvider] for [cacheWidth] semantics.
ImageProvider? getImageProvider(String? imagePath, {int? cacheWidth}) {
  final provider = _resolveImageProvider(imagePath);
  if (provider == null) return null;
  return cacheWidth == null ? provider : ResizeImage(provider, width: cacheWidth);
}

ImageProvider? _resolveImageProvider(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return null;
  }

  final dataUriImage = _memoryImageFromDataUri(imagePath);
  if (dataUriImage != null) {
    return dataUriImage;
  }

  if (imagePath.startsWith('assets/')) {
    return _assetImageProvider(imagePath);
  }

  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return _networkImageProvider(imagePath);
  }

  // Check if it's a local file path (from camera/gallery picker)
  if (imagePath.startsWith('/') ||
      imagePath.contains('\\') ||
      imagePath.contains('cache') ||
      imagePath.contains('tmp')) {
    final file = _existingLocalFile(imagePath);
    if (file != null) return FileImage(file);
  }

  return _assetImageProvider(imagePath);
}

/// Max entries kept per provider-memoization map below. These only cache
/// small [ImageProvider] wrapper objects (not decoded bytes — Flutter's own
/// image cache already governs decoded-bytes memory), but with no bound at
/// all they'd grow for the entire process lifetime as new avatar/image URLs
/// are scrolled past. Evicts oldest-inserted first once the cap is hit.
const int _maxCachedImageProviders = 200;

void _capMap(Map<String, Object> map) {
  if (map.length <= _maxCachedImageProviders) return;
  final excess = map.length - _maxCachedImageProviders;
  for (final key in map.keys.take(excess).toList()) {
    map.remove(key);
  }
}

AssetImage _assetImageProvider(String path) {
  final image = _assetImageCache.putIfAbsent(path, () => AssetImage(path));
  _capMap(_assetImageCache);
  return image;
}

NetworkImage _networkImageProvider(String url) {
  final image = _networkImageCache.putIfAbsent(url, () => NetworkImage(url));
  _capMap(_networkImageCache);
  return image;
}

FileImage _fileImageProvider(String path) {
  final image = _fileImageCache.putIfAbsent(path, () => FileImage(File(path)));
  _capMap(_fileImageCache);
  return image;
}

MemoryImage? _memoryImageFromDataUri(String path) {
  if (!_isBase64DataImage(path)) return null;

  final cached = _memoryImageCache[path];
  if (cached != null) return cached;

  try {
    final commaIndex = path.indexOf(',');
    if (commaIndex <= 0 || commaIndex == path.length - 1) return null;

    final encoded = path.substring(commaIndex + 1);
    final bytes = base64Decode(encoded);
    final image = MemoryImage(bytes);
    _memoryImageCache[path] = image;
    _capMap(_memoryImageCache);
    return image;
  } catch (_) {
    return null;
  }
}

bool _isBase64DataImage(String value) {
  return value.startsWith('data:image/') && value.contains(';base64,');
}

File? _existingLocalFile(String path) {
  try {
    final normalizedPath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    final file = File(normalizedPath);
    return file.existsSync() ? file : null;
  } catch (_) {
    return null;
  }
}
