import '../../enums/index.dart';

/// 创作流程中可选的视频素材。
///
/// 可来自用户上传、历史素材库或后端素材列表。
final class CreationMaterial {
  const CreationMaterial({
    required this.id,
    required this.name,
    required this.durationText,
    required this.durationSeconds,
    required this.thumbUrl,
    required this.status,
    this.filePath,
    this.fileSize = 0,
    this.contentType = 'video/mp4',
    this.type = 'VIDEO',
  });

  /// 素材唯一 id。
  final String id;

  /// 素材展示名称。
  final String name;

  /// 已格式化的视频时长文案。
  final String durationText;

  /// 视频时长秒数，用于汇总和限制判断。
  final int durationSeconds;

  /// 素材封面图地址。
  final String thumbUrl;

  /// 素材处理状态。
  final MaterialStatus status;

  /// 本机视频文件路径，仅前端本地选择后存在。
  final String? filePath;

  /// 本机视频文件大小，单位字节。
  final int fileSize;

  /// 本机视频 MIME 类型。
  final String contentType;

  /// 后端上传类型。当前视频解说只上传视频素材。
  final String type;

  factory CreationMaterial.fromJson(Map<String, dynamic> json) {
    return CreationMaterial(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      durationText: '${json['durationText'] ?? ''}',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      thumbUrl: '${json['thumbUrl'] ?? json['coverUrl'] ?? ''}',
      status: _materialStatus(json['status']),
      filePath: json['filePath'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      contentType: '${json['contentType'] ?? 'video/mp4'}',
      type: '${json['type'] ?? 'VIDEO'}',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'durationText': durationText,
      'durationSeconds': durationSeconds,
      'thumbUrl': thumbUrl,
      'status': status.name,
      if (filePath != null) 'filePath': filePath,
      'fileSize': fileSize,
      'contentType': contentType,
      'type': type,
    };
  }
}

MaterialStatus _materialStatus(Object? value) {
  return MaterialStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => MaterialStatus.ready,
  );
}
