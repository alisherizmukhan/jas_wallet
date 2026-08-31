import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Result of image picking operation
class ImagePickResult {
  final File? file;
  final String? path;
  final String? error;
  final bool cancelled;

  const ImagePickResult._({
    this.file,
    this.path,
    this.error,
    this.cancelled = false,
  });

  factory ImagePickResult.success(File file) => ImagePickResult._(
        file: file,
        path: file.path,
      );

  factory ImagePickResult.cancelled() => const ImagePickResult._(cancelled: true);

  factory ImagePickResult.error(String message) => ImagePickResult._(error: message);

  bool get isSuccess => file != null && error == null && !cancelled;
}

/// Service for picking images from camera or gallery
class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();
  bool _isPickerActive = false;
  LostDataResponse? _pendingLostData;
  bool _lostDataChecked = false;

  static const double cardAspectRatio = 1.586;

  /// Pick image from camera
  Future<ImagePickResult> pickFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    if (_isPickerActive) return ImagePickResult.cancelled();
    _isPickerActive = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (image == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(image.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    } finally {
      _isPickerActive = false;
    }
  }

  /// Pick image from gallery
  Future<ImagePickResult> pickFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (_isPickerActive) return ImagePickResult.cancelled();
    _isPickerActive = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (image == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(image.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    } finally {
      _isPickerActive = false;
    }
  }

  /// Pick multiple images from gallery
  Future<List<ImagePickResult>> pickMultipleFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    if (_isPickerActive) return [ImagePickResult.cancelled()];
    final recovered = _consumeRecoveredMultiple();
    if (recovered != null) return recovered;
    _isPickerActive = true;
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        limit: limit,
      );

      if (images.isEmpty) {
        return [ImagePickResult.cancelled()];
      }

      return images.map((image) => ImagePickResult.success(File(image.path))).toList();
    } catch (e) {
      return [ImagePickResult.error(e.toString())];
    } finally {
      _isPickerActive = false;
    }
  }

  /// Crop an image file with circular UI for avatar
  Future<ImagePickResult> cropImage(String sourcePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 800,
        maxHeight: 800,
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            cropStyle: CropStyle.circle,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: '',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
        ],
      );

      if (croppedFile == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(croppedFile.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    }
  }

  /// Crop an image file with card-like rectangle ratio for Salto card design.
  Future<ImagePickResult> cropCardImage(String sourcePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(
          ratioX: cardAspectRatio,
          ratioY: 1,
        ),
        compressQuality: 100,
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            cropStyle: CropStyle.rectangle,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: '',
            cropStyle: CropStyle.rectangle,
            aspectRatioLockEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
        ],
      );

      if (croppedFile == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(croppedFile.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    }
  }

  /// Pick video from camera
  Future<ImagePickResult> pickVideoFromCamera({
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    if (_isPickerActive) return ImagePickResult.cancelled();
    final recovered = _consumeRecoveredSingle();
    if (recovered != null) return recovered;
    _isPickerActive = true;
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (video == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(video.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    } finally {
      _isPickerActive = false;
    }
  }

  /// Pick video from gallery
  Future<ImagePickResult> pickVideoFromGallery({
    Duration? maxDuration,
  }) async {
    if (_isPickerActive) return ImagePickResult.cancelled();
    final recovered = _consumeRecoveredSingle();
    if (recovered != null) return recovered;
    _isPickerActive = true;
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );

      if (video == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(video.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    } finally {
      _isPickerActive = false;
    }
  }

  /// Pick media (image or video) from gallery
  Future<ImagePickResult> pickMedia({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (_isPickerActive) return ImagePickResult.cancelled();
    final recovered = _consumeRecoveredSingle();
    if (recovered != null) return recovered;
    _isPickerActive = true;
    try {
      final XFile? media = await _picker.pickMedia(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (media == null) {
        return ImagePickResult.cancelled();
      }

      return ImagePickResult.success(File(media.path));
    } catch (e) {
      return ImagePickResult.error(e.toString());
    } finally {
      _isPickerActive = false;
    }
  }

  /// Retrieve lost data (Android only)
  /// Call this on app startup to recover images from killed processes
  Future<LostDataResponse?> retrieveLostData() async {
    if (kIsWeb) return null;
    
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return null;
      }
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Best-effort startup recovery for Android picker flows.
  ///
  /// The next picker request will consume this pending result instead of
  /// launching a new picker intent, which matches the recommended recovery
  /// pattern from image_picker docs.
  Future<void> primeLostData() async {
    if (_lostDataChecked) return;
    _lostDataChecked = true;
    _pendingLostData = await retrieveLostData();
  }

  ImagePickResult? _consumeRecoveredSingle() {
    final response = _pendingLostData;
    if (response == null) return null;
    _pendingLostData = null;

    final files = response.files;
    if (files != null && files.isNotEmpty) {
      return ImagePickResult.success(File(files.first.path));
    }

    final exception = response.exception;
    if (exception != null) {
      return ImagePickResult.error(exception.toString());
    }

    return ImagePickResult.cancelled();
  }

  List<ImagePickResult>? _consumeRecoveredMultiple() {
    final response = _pendingLostData;
    if (response == null) return null;
    _pendingLostData = null;

    final files = response.files;
    if (files != null && files.isNotEmpty) {
      return files.map((file) => ImagePickResult.success(File(file.path))).toList();
    }

    final exception = response.exception;
    if (exception != null) {
      return [ImagePickResult.error(exception.toString())];
    }

    return [ImagePickResult.cancelled()];
  }
}

/// Extension for easy image picking with context
extension ImagePickerContext on BuildContext {
  ImagePickerService get imagePicker => ImagePickerService();
}
