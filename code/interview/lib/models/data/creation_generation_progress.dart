/// 视频解说任务在前端提交过程中的阶段。
///
/// 这些阶段只描述“提交前后”的本地交互进度，真正的生成状态以后端
/// `QuickGenerationBatch.status` 和作品状态为准。
enum CreationGenerationPhase {
  idle,
  creating,
  uploading,
  reporting,
  submitting,
  polling,
  succeeded,
  failed,
}

/// 上传/提交弹窗展示用的进度快照。
///
/// Controller 每推进一个异步步骤都会整体替换该对象，页面只负责订阅渲染。
final class CreationGenerationProgress {
  const CreationGenerationProgress({
    required this.phase,
    required this.message,
    required this.progress,
    this.current = 0,
    this.total = 0,
    this.errorMessage,
  });

  /// 初始空闲状态，表示当前没有上传或提交任务。
  const CreationGenerationProgress.idle()
    : phase = CreationGenerationPhase.idle,
      message = '',
      progress = 0,
      current = 0,
      total = 0,
      errorMessage = null;

  /// 当前提交阶段。
  final CreationGenerationPhase phase;

  /// 当前阶段展示给用户的短文案。
  final String message;

  /// 整体提交进度，取值范围为 0 到 1。
  final double progress;

  /// 当前正在处理的视频序号。
  final int current;

  /// 本次提交的视频总数。
  final int total;

  /// 失败时展示给用户的错误原因。
  final String? errorMessage;

  /// 是否处于失败态。
  bool get isFailed => phase == CreationGenerationPhase.failed;

  /// 是否处于非空闲、非失败的执行态。
  bool get isBusy => !isFailed && phase != CreationGenerationPhase.idle;

  /// 复制当前快照并替换指定字段。
  CreationGenerationProgress copyWith({
    CreationGenerationPhase? phase,
    String? message,
    double? progress,
    int? current,
    int? total,
    String? errorMessage,
  }) {
    return CreationGenerationProgress(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      current: current ?? this.current,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}
