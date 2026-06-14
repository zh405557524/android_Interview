/// 快速批量生成中待上传的视频文件。
///
/// 步骤1：前端选择多个视频并读取元信息。
/// 用于创建 quick batch 时向后端申报文件信息和预估积分，不包含视频二进制。
final class QuickGenerationFile {
  const QuickGenerationFile({
    required this.clientFileId,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    required this.durationSeconds,
    this.type = 'VIDEO',
  });

  /// 前端生成的临时文件 id，用于把步骤3返回的上传凭证匹配回本地文件。
  final String clientFileId;

  /// 步骤1读取到的视频文件名。
  final String fileName;

  /// 步骤1读取到的视频文件大小，单位字节。
  final int fileSize;

  /// 步骤1读取到的视频 MIME 类型。
  final String contentType;

  /// 上传素材类型，后端据此区分百度上传资源类别。
  final String type;

  /// 步骤1读取或申报的视频时长秒数，用于步骤2上传前积分冻结。
  final int durationSeconds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'clientFileId': clientFileId,
      'fileName': fileName,
      'fileSize': fileSize,
      'contentType': contentType,
      'type': type,
      'durationSeconds': durationSeconds,
    };
  }
}
