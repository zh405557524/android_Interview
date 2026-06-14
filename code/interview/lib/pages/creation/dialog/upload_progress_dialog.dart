part of '../index.dart';

/// 生成提交弹层的异步执行函数。
typedef CreationGenerationRunner = Future<QuickGenerationBatch?> Function();

/// 展示上传/提交进度弹层，成功时返回后端批次。
Future<QuickGenerationBatch?> showCreationUploadProgressDialog(
  BuildContext context, {
  required Rx<CreationGenerationProgress> progress,
  required CreationGenerationRunner onStart,
  required CreationGenerationRunner onRetry,
}) {
  return showDialog<QuickGenerationBatch>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (context) {
      return _CreationUploadProgressDialog(
        progress: progress,
        onStart: onStart,
        onRetry: onRetry,
      );
    },
  );
}

/// 上传进度弹层，只订阅进度和触发回调，不持有 Controller。
class _CreationUploadProgressDialog extends StatefulWidget {
  const _CreationUploadProgressDialog({
    required this.progress,
    required this.onStart,
    required this.onRetry,
  });

  /// 弹层展示的进度状态。
  final Rx<CreationGenerationProgress> progress;

  /// 首次进入弹层时执行的生成提交动作。
  final CreationGenerationRunner onStart;

  /// 失败后点击重试时执行的生成提交动作。
  final CreationGenerationRunner onRetry;

  @override
  State<_CreationUploadProgressDialog> createState() =>
      _CreationUploadProgressDialogState();
}

class _CreationUploadProgressDialogState
    extends State<_CreationUploadProgressDialog> {
  /// 防止用户连续点击重试导致重复提交。
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run(firstRun: true);
    });
  }

  /// 执行首次提交或失败重试，并在成功后关闭弹层。
  Future<void> _run({required bool firstRun}) async {
    if (_running) {
      return;
    }
    setState(() {
      _running = true;
    });
    final batch = firstRun ? await widget.onStart() : await widget.onRetry();
    if (!mounted) {
      return;
    }
    if (batch != null && !widget.progress.value.isFailed) {
      Navigator.of(context).pop(batch);
      return;
    }
    setState(() {
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = widget.progress.value;
      final failed = progress.isFailed;
      final percent = (progress.progress.clamp(0.0, 1.0) * 100).round();

      return PopScope(
        canPop: failed && !_running,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Container(
            width: 312.w,
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
            decoration: BoxDecoration(
              color: const Color(0xFF071007),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: failed ? const Color(0xFFFF6B6B) : CustomTheme.primary,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        failed ? '提交失败' : '正在创建作品',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!failed)
                      SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4.r,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            CustomTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 18.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    minHeight: 8.h,
                    value: progress.progress.clamp(0.0, 1.0).toDouble(),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      failed ? const Color(0xFFFF6B6B) : CustomTheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress.message.isEmpty
                            ? '准备上传视频...'
                            : progress.message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 13.sp,
                          height: 1.35,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: failed
                            ? const Color(0xFFFFA0A0)
                            : CustomTheme.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (progress.total > 0) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '${progress.current}/${progress.total} 个视频',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                if (failed && progress.errorMessage?.isNotEmpty == true) ...[
                  SizedBox(height: 14.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      progress.errorMessage!,
                      style: TextStyle(
                        color: const Color(0xFFFFD2D2),
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                if (failed) ...[
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _running
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('关闭'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: FilledButton(
                          onPressed: _running
                              ? null
                              : () => _run(firstRun: false),
                          style: FilledButton.styleFrom(
                            backgroundColor: CustomTheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: const Text('重试'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
