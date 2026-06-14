part of 'index.dart';

/// 作品视频下载与保存服务。
///
/// 该服务只处理百度临时下载地址，不复用业务 HttpService，避免把 App 业务鉴权头
/// 带到第三方预签名 URL 上导致下载失败。
final class WorkDownloadService {
  WorkDownloadService._();

  static final Dio _downloadDio = Dio();

  /// 下载视频到临时目录并保存到系统相册。
  ///
  /// [onProgress] 只负责向 UI 汇报阶段与进度，不持有页面状态。
  static Future<void> saveVideoToGallery({
    required BuildContext context,
    required String url,
    required String workId,
    void Function(double progress, String message)? onProgress,
  }) async {
    final downloadUrl = url.trim();
    if (downloadUrl.isEmpty) {
      throw const WorkDownloadException('下载地址不存在');
    }

    final hasPermission = await Access.saveVideoToGallery(context);
    if (!hasPermission) {
      throw const WorkDownloadException('没有相册/存储权限，无法保存视频');
    }

    File? tempFile;
    try {
      onProgress?.call(0.08, '准备下载视频...');
      tempFile = await _createTempVideoFile(workId);
      await _downloadVideo(
        url: downloadUrl,
        savePath: tempFile.path,
        onProgress: onProgress,
      );
      await _saveFile(tempFile.path);
      onProgress?.call(1, '视频已保存到相册');
    } finally {
      await _deleteQuietly(tempFile);
    }
  }

  /// 在系统临时目录创建本次下载文件路径。
  static Future<File> _createTempVideoFile(String workId) async {
    final directory = await getTemporaryDirectory();
    final safeWorkId = _safeFileName(workId.isEmpty ? 'work' : workId);
    final fileName =
        'narrate_${safeWorkId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
    return file;
  }

  /// 下载第三方临时视频 URL，并把下载进度映射到 10%~82%。
  static Future<void> _downloadVideo({
    required String url,
    required String savePath,
    required void Function(double progress, String message)? onProgress,
  }) async {
    try {
      await _downloadDio.download(
        url,
        savePath,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total <= 0) {
            onProgress?.call(0.2, '正在下载视频...');
            return;
          }
          final downloadProgress = received / total;
          final progress = 0.1 + downloadProgress.clamp(0, 1) * 0.72;
          onProgress?.call(progress, '正在下载视频...');
        },
      );
    } on DioException catch (error) {
      throw WorkDownloadException(_downloadErrorMessage(error));
    }
  }

  /// 将临时文件写入系统相册，并校验插件返回的保存结果。
  static Future<void> _saveFile(String path) async {
    final file = File(path);
    if (!await file.exists() || await file.length() <= 0) {
      throw const WorkDownloadException('视频下载失败，请重试');
    }

    final result = await ImageGallerySaverPlus.saveFile(path);
    if (result is Map && result['isSuccess'] == true) {
      return;
    }
    throw const WorkDownloadException('保存到相册失败，请重试');
  }

  /// 清理临时文件；清理失败不影响用户已完成的保存结果。
  static Future<void> _deleteQuietly(File? file) async {
    try {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 临时文件清理失败不影响主流程，系统临时目录后续也会回收。
    }
  }

  /// 生成安全文件名片段，避免作品 id 中的特殊字符影响临时路径。
  static String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  }

  /// 将 Dio 下载异常转换为用户可读提示。
  static String _downloadErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400) {
      return '视频下载失败，请稍后重试';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络设置';
    }
    return '视频下载失败，请重试';
  }
}

/// 作品下载保存过程中的用户可读错误。
final class WorkDownloadException implements Exception {
  const WorkDownloadException(this.message);

  /// 可直接展示给用户的错误文案。
  final String message;

  @override
  String toString() => message;
}
