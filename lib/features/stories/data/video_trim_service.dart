import 'package:flutter/services.dart';

/// Calls the native platform (Android MediaMuxer / iOS AVAssetExportSession)
/// to do a fast, lossless container-level video trim — no re-encoding.
class VideoTrimService {
  const VideoTrimService._();

  static const _channel = MethodChannel('com.jaswallet/video_trim');

  /// Trims [inputPath] to [startMs]..[endMs] and writes the result to
  /// [outputPath].  Returns [outputPath] on success, throws [PlatformException]
  /// on failure.
  static Future<String> trimVideo({
    required String inputPath,
    required String outputPath,
    required int startMs,
    required int endMs,
  }) async {
    final result = await _channel.invokeMethod<String>('trimVideo', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'startMs': startMs,
      'endMs': endMs,
    });
    if (result == null) {
      throw PlatformException(
        code: 'TRIM_FAILED',
        message: 'Native trim returned no result',
      );
    }
    return result;
  }
}
