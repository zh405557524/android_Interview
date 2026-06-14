part of 'index.dart';

/// 视频文件工具。
///
/// 参考 `clip-flutter` 的 `VideoUtils`：缩略图优先使用 `VideoCompress` 生成文件，
/// 如果原生插件返回空路径或空文件，再用 `video_thumbnail` 解帧并写入临时目录。
abstract final class VideoUtils {
  /// 获取视频时长，单位秒。
  ///
  /// 当前创作页仍用 `video_player` 读取时长；这里保留同名工具方法，方便后续页面复用。
  static Future<double?> getVideoDuration(String videoPath) async {
    try {
      final mediaInfo = await VideoCompress.getMediaInfo(videoPath);
      final duration = mediaInfo.duration;
      if (duration == null || duration <= 0) {
        return 0;
      }
      return Duration(milliseconds: duration.toInt()).inSeconds.toDouble();
    } catch (error) {
      AppLogger.error('[VideoUtils] get video duration failed', error);
      return 0;
    }
  }

  /// 获取视频时长，单位毫秒。
  static Future<double?> getVideoMilliseconds(String videoPath) async {
    try {
      final mediaInfo = await VideoCompress.getMediaInfo(videoPath);
      final duration = mediaInfo.duration;
      if (duration == null || duration <= 0) {
        return 0;
      }
      return Duration(milliseconds: duration.toInt()).inMilliseconds.toDouble();
    } catch (error) {
      AppLogger.error('[VideoUtils] get video milliseconds failed', error);
      return 0;
    }
  }

  /// 生成第一帧附近的视频缩略图文件。
  ///
  /// 返回本地 jpg 文件路径；如果多个方案都失败，返回 `null`。
  static Future<String?> getFileThumbnail(String videoPath) {
    return getFileThumbnail2(videoPath, 0);
  }

  /// 按指定毫秒位置生成视频缩略图文件。
  ///
  /// 部分 iOS 视频在 0ms 没有可解码关键帧，因此会按 `timeMs -> 500ms -> 1000ms`
  /// 顺序兜底尝试，保证封面上传和本地预览尽量拿到真实图片。
  static Future<String?> getFileThumbnail2(String videoPath, int timeMs) async {
    final file = File(videoPath);
    if (!file.existsSync()) {
      AppLogger.error('[VideoUtils] video file not found: $videoPath');
      return null;
    }

    final positions = <int>{timeMs, 500, 1000}.where((item) => item >= 0);
    for (final position in positions) {
      final compressedPath = await _videoCompressThumbnail(videoPath, position);
      if (compressedPath != null) {
        return compressedPath;
      }

      final thumbnailPath = await _videoThumbnailFile(videoPath, position);
      if (thumbnailPath != null) {
        return thumbnailPath;
      }
    }

    AppLogger.error('[VideoUtils] video thumbnail generated empty path');
    return null;
  }

  /// 获取视频缩略图内存数据。
  ///
  /// 该方法主要给需要 `Image.memory` 的场景使用；创作页上传封面请使用
  /// [getFileThumbnail]，因为后端接口需要真实文件。
  static Future<Uint8List?> getVideoThumbnail(
    String videoPath, {
    int timeMs = 0,
    int quality = 75,
  }) async {
    try {
      return VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: quality,
        timeMs: timeMs,
      );
    } catch (error) {
      AppLogger.error('[VideoUtils] get video thumbnail data failed', error);
      return null;
    }
  }

  static Future<String?> _videoCompressThumbnail(
    String videoPath,
    int position,
  ) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 75,
        position: position,
      );
      return _validThumbnailPath(thumbnailFile.path);
    } on MissingPluginException catch (error) {
      AppLogger.error('[VideoUtils] video_compress missing plugin', error);
      return null;
    } on PlatformException catch (error) {
      AppLogger.error('[VideoUtils] video_compress platform error', error);
      return null;
    } catch (error) {
      AppLogger.error('[VideoUtils] video_compress thumbnail failed', error);
      return null;
    }
  }

  static Future<String?> _videoThumbnailFile(
    String videoPath,
    int timeMs,
  ) async {
    try {
      final outputPath = await _thumbnailOutputPath(videoPath, timeMs);
      final path = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: outputPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        timeMs: timeMs,
        quality: 75,
      );
      final validPath = _validThumbnailPath(path);
      if (validPath != null) {
        return validPath;
      }

      return _writeThumbnailData(
        videoPath: videoPath,
        outputPath: outputPath,
        timeMs: timeMs,
      );
    } on MissingPluginException catch (error) {
      AppLogger.error('[VideoUtils] video_thumbnail missing plugin', error);
      return null;
    } on PlatformException catch (error) {
      AppLogger.error('[VideoUtils] video_thumbnail platform error', error);
      return null;
    } catch (error) {
      AppLogger.error('[VideoUtils] video_thumbnail file failed', error);
      return null;
    }
  }

  static Future<String> _thumbnailOutputPath(
    String videoPath,
    int timeMs,
  ) async {
    final directory = Directory(
      '${Directory.systemTemp.path}/narrate_thumbnails',
    );
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final file = File(videoPath);
    final fileName = file.uri.pathSegments.isEmpty
        ? 'video'
        : file.uri.pathSegments.last;
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final stat = await file.stat();
    final seed =
        '${safeName}_${stat.size}_${stat.modified.millisecondsSinceEpoch}_$timeMs';
    return '${directory.path}/$seed.jpg';
  }

  static String? _validThumbnailPath(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final thumbnail = File(value);
    if (!thumbnail.existsSync() || thumbnail.lengthSync() <= 0) {
      return null;
    }
    return thumbnail.path;
  }

  static Future<String?> _writeThumbnailData({
    required String videoPath,
    required String outputPath,
    required int timeMs,
  }) async {
    final bytes = await getVideoThumbnail(videoPath, timeMs: timeMs);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final output = File(outputPath);
    await output.writeAsBytes(bytes, flush: true);
    return _validThumbnailPath(output.path);
  }
}
