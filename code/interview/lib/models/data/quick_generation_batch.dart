import '../../enums/index.dart';

/// 快速批量生成批次。
///
/// 表示一次多视频上传自动生成一个作品的完整异步状态。
/// 覆盖步骤2创建批次、步骤4前端直传、步骤5完成上报、步骤6创建项目和步骤8返回作品。
final class QuickGenerationBatch {
  const QuickGenerationBatch({
    required this.batchId,
    required this.status,
    required this.totalCount,
    required this.uploadedCount,
    required this.pointsCost,
    required this.uploadItems,
    this.providerTaskId,
    this.workId,
    this.failureMessage,
  });

  /// 快速生成批次 id，步骤5完成上报和状态轮询都会使用。
  final String batchId;

  /// 当前批次状态：uploading、generating、succeeded、failed。
  final QuickGenerationBatchStatus status;

  /// 步骤1选择的视频总数。
  final int totalCount;

  /// 已完成步骤5 upload-complete 的视频数量。
  final int uploadedCount;

  /// 步骤2预计积分，或步骤6按真实时长复核后的最终积分。
  final int pointsCost;

  /// 步骤6提交后返回的百度智能集锦任务 id。
  final String? providerTaskId;

  /// 后端创建本地作品后返回的作品 id；拿到后上传弹框即可关闭。
  final String? workId;

  /// 批次失败时的错误说明。
  final String? failureMessage;

  /// 步骤3返回的每个视频上传凭证和状态。
  final List<QuickBatchUploadItem> uploadItems;

  factory QuickGenerationBatch.fromJson(Map<String, dynamic> json) {
    return QuickGenerationBatch(
      batchId: '${json['batchId'] ?? ''}',
      status: _quickBatchStatus(json['status']),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      uploadedCount: (json['uploadedCount'] as num?)?.toInt() ?? 0,
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      providerTaskId: json['providerTaskId'] as String?,
      workId: json['workId'] as String?,
      failureMessage: json['failureMessage'] as String?,
      uploadItems: (json['uploadItems'] as List? ?? const <dynamic>[]).map((
        item,
      ) {
        return QuickBatchUploadItem.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList(),
    );
  }
}

/// 快速批次中单个视频的上传凭证和状态。
///
/// 前端用 clientFileId 找到本地文件，用 uploadUrl/uploadHeaders 完成步骤4：
/// 前端将视频文件直传到 uploadUrl，再用 assetId 执行步骤5完成上报。
final class QuickBatchUploadItem {
  const QuickBatchUploadItem({
    required this.clientFileId,
    required this.assetId,
    required this.status,
    required this.uploadUrl,
    required this.uploadHeaders,
    this.expiresAt,
  });

  /// 步骤1生成的前端临时文件 id。
  final String clientFileId;

  /// 后端本地媒资 id，步骤5 upload-complete 的路径参数。
  final String assetId;

  /// 单个视频上传状态：processing、ready、failed。
  final MaterialStatus status;

  /// 步骤4前端直传视频文件的百度 VOD 地址；当前 Mock Provider 返回 mock 地址。
  final String uploadUrl;

  /// 步骤4前端直传时需要带上的百度 VOD 请求头。
  final Map<String, String> uploadHeaders;

  /// 上传凭证过期时间，过期后不能继续步骤4直传。
  final DateTime? expiresAt;

  factory QuickBatchUploadItem.fromJson(Map<String, dynamic> json) {
    return QuickBatchUploadItem(
      clientFileId: '${json['clientFileId'] ?? ''}',
      assetId: '${json['assetId'] ?? ''}',
      status: _materialStatus(json['status']),
      uploadUrl: '${json['uploadUrl'] ?? ''}',
      uploadHeaders: (json['uploadHeaders'] as Map? ?? const <String, String>{})
          .map((key, value) => MapEntry('$key', '$value')),
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
    );
  }
}

QuickGenerationBatchStatus _quickBatchStatus(Object? value) {
  final normalized = '${value ?? ''}'.trim().toLowerCase();
  return switch (normalized) {
    'uploaded' => QuickGenerationBatchStatus.uploaded,
    'analyzing' => QuickGenerationBatchStatus.analyzing,
    'generating' ||
    'running' ||
    'submitted' => QuickGenerationBatchStatus.generating,
    'success' ||
    'succeeded' ||
    'completed' => QuickGenerationBatchStatus.succeeded,
    'failed' || 'failure' => QuickGenerationBatchStatus.failed,
    'canceled' || 'cancelled' => QuickGenerationBatchStatus.canceled,
    'expired' => QuickGenerationBatchStatus.expired,
    _ => QuickGenerationBatchStatus.uploading,
  };
}

MaterialStatus _materialStatus(Object? value) {
  final normalized = '${value ?? ''}'.toLowerCase();
  return switch (normalized) {
    'uploaded' || 'ready' => MaterialStatus.ready,
    'failed' => MaterialStatus.failed,
    _ => MaterialStatus.processing,
  };
}
