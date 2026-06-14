part of '../index.dart';

/// 创作页本地视频预览弹框。
///
/// 弹框只接收本地文件与标题，不持有 Controller；调用方负责判断文件是否有效。
class CreationVideoPreviewDialog extends StatelessWidget {
  const CreationVideoPreviewDialog({
    super.key,
    required this.file,
    required this.title,
  });

  /// 需要预览的本地视频文件。
  final File file;

  /// 顶部展示的视频标题。
  final String title;

  /// 打开创作页本地视频预览弹框。
  static Future<void> show({
    required BuildContext context,
    required File file,
    required String title,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭视频预览',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) {
        return CreationVideoPreviewDialog(file: file, title: title);
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CreationVideoPreviewBody(file: file, title: title);
  }
}

/// 本地视频预览弹框主体，由私有 StatefulWidget 托管播放器生命周期。
class _CreationVideoPreviewBody extends StatefulWidget {
  const _CreationVideoPreviewBody({required this.file, required this.title});

  /// 需要预览的本地视频文件。
  final File file;

  /// 顶部展示的视频标题。
  final String title;

  @override
  State<_CreationVideoPreviewBody> createState() =>
      _CreationVideoPreviewBodyState();
}

class _CreationVideoPreviewBodyState extends State<_CreationVideoPreviewBody> {
  /// 当前本地视频播放器。
  late final VideoPlayerController _controller;

  /// 初始化任务，用于驱动加载、错误和播放器状态。
  late final Future<void> _initializeFuture;

  /// 视频初始化失败时展示的用户可读文案。
  String? _errorMessage;

  /// 视频宽高比，异常素材兜底为 16:9，避免布局塌陷。
  double get _aspectRatio {
    final ratio = _controller.value.aspectRatio;
    if (ratio <= 0 || ratio.isNaN || ratio.isInfinite) {
      return 16 / 9;
    }
    return ratio;
  }

  /// 当前视频是否已经完成播放器初始化。
  bool get _initialized => _controller.value.isInitialized;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _controller.addListener(_handleVideoChanged);
    _initializeFuture = _initializeVideo();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoChanged);
    unawaited(_controller.dispose());
    super.dispose();
  }

  /// 初始化本地视频，并默认开始播放。
  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      await _controller.play();
      setState(() {
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '视频加载失败，请重新选择';
      });
    }
  }

  /// 监听播放进度和播放状态变化，刷新底部控制栏。
  void _handleVideoChanged() {
    if (!mounted || !_initialized) {
      return;
    }
    setState(() {});
  }

  /// 切换播放与暂停状态。
  Future<void> _togglePlayback() async {
    if (!_initialized) {
      return;
    }
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: FutureBuilder<void>(
                future: _initializeFuture,
                builder: (context, snapshot) {
                  if (_errorMessage?.isNotEmpty == true) {
                    return _CreationVideoPreviewError(message: _errorMessage!);
                  }
                  if (snapshot.connectionState != ConnectionState.done ||
                      !_initialized) {
                    return const _CreationVideoPreviewLoading();
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => unawaited(_togglePlayback()),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          _CreationVideoPreviewPlayOverlay(
                            onTap: () => unawaited(_togglePlayback()),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 14.w,
              right: 14.w,
              top: 10.h,
              child: _CreationVideoPreviewHeader(
                title: widget.title,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
            if (_initialized)
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 18.h,
                child: _CreationVideoPreviewControls(
                  controller: _controller,
                  onTogglePlayback: () => unawaited(_togglePlayback()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 视频预览顶部标题与关闭按钮。
class _CreationVideoPreviewHeader extends StatelessWidget {
  const _CreationVideoPreviewHeader({
    required this.title,
    required this.onClose,
  });

  /// 顶部显示的视频名称。
  final String title;

  /// 关闭弹窗回调。
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CreationVideoPreviewRoundButton(
          icon: Icons.close_rounded,
          tooltip: '关闭',
          onTap: onClose,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 42.r),
      ],
    );
  }
}

/// 视频预览底部播放进度控制栏。
class _CreationVideoPreviewControls extends StatelessWidget {
  const _CreationVideoPreviewControls({
    required this.controller,
    required this.onTogglePlayback,
  });

  /// 当前播放器实例。
  final VideoPlayerController controller;

  /// 播放/暂停按钮回调。
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _CreationVideoPreviewRoundButton(
            icon: value.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            tooltip: value.isPlaying ? '暂停' : '播放',
            onTap: onTogglePlayback,
            size: 34.r,
            iconSize: 22.r,
          ),
          SizedBox(width: 10.w),
          Text(
            _formatCreationVideoDuration(value.position),
            style: TextStyle(color: Colors.white, fontSize: 11.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              colors: VideoProgressColors(
                playedColor: CustomTheme.primary,
                bufferedColor: Colors.white.withValues(alpha: 0.35),
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            _formatCreationVideoDuration(value.duration),
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

/// 视频暂停时居中的播放按钮。
class _CreationVideoPreviewPlayOverlay extends StatelessWidget {
  const _CreationVideoPreviewPlayOverlay({required this.onTap});

  /// 点击后恢复播放。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CreationVideoPreviewRoundButton(
      icon: Icons.play_arrow_rounded,
      tooltip: '播放',
      onTap: onTap,
      size: 58.r,
      iconSize: 34.r,
    );
  }
}

/// 视频加载中的占位状态。
class _CreationVideoPreviewLoading extends StatelessWidget {
  const _CreationVideoPreviewLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28.r,
          height: 28.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.6.r,
            color: CustomTheme.primary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          '视频加载中...',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
        ),
      ],
    );
  }
}

/// 视频加载失败状态。
class _CreationVideoPreviewError extends StatelessWidget {
  const _CreationVideoPreviewError({required this.message});

  /// 用户可读错误文案。
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: CustomTheme.danger,
            size: 36.r,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 14.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// 视频预览中的圆形图标按钮。
class _CreationVideoPreviewRoundButton extends StatelessWidget {
  const _CreationVideoPreviewRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size,
    this.iconSize,
  });

  /// 按钮图标。
  final IconData icon;

  /// 无障碍与长按提示文案。
  final String tooltip;

  /// 点击回调。
  final VoidCallback onTap;

  /// 按钮尺寸。
  final double? size;

  /// 图标尺寸。
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 38.r;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize ?? 20.r),
        ),
      ),
    );
  }
}

/// 把视频时长格式化为 `mm:ss` 或 `hh:mm:ss`。
String _formatCreationVideoDuration(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}
