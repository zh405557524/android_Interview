part of 'index.dart';

class WorkDetailPage extends StatefulWidget {
  const WorkDetailPage({required this.workId, super.key});

  final String workId;

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  late WorkDetailController controller;
  int _selectedVariantIndex = 0;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant WorkDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workId == widget.workId) {
      return;
    }
    _deleteController(oldWidget.workId);
    _bindController();
  }

  @override
  void dispose() {
    _deleteController(widget.workId);
    super.dispose();
  }

  void _bindController() {
    final tag = widget.workId;
    controller = putFreshController(
      WorkDetailController(workId: tag),
      tag: tag,
    );
  }

  void _deleteController(String tag) {
    deleteControllerIfCurrent(controller, tag: tag);
  }

  int _safeVariantIndex(WorkDetail? detail) {
    final count = detail?.videoVariants.length ?? 0;
    if (count <= 1) {
      return 0;
    }
    if (_selectedVariantIndex < 0 || _selectedVariantIndex >= count) {
      return 0;
    }
    return _selectedVariantIndex;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        toolbarHeight: 48.h,
        leadingWidth: 52.w,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          tooltip: '返回',
        ),
        title: Text(
          '作品详情',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071306), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Obx(
                  () => AppStateBuilder(
                    state: controller.pageState,
                    loadingMessage: '加载作品详情...',
                    errorMessage: controller.errorMessage.value ?? '作品详情加载失败',
                    notFoundMessage: '作品不存在或已失效',
                    onRetry: controller.loadDetail,
                    builder: (_) {
                      final detail = controller.detail.value!;
                      final variantIndex = _safeVariantIndex(detail);
                      return ListView(
                        padding: EdgeInsets.only(bottom: 110.h),
                        children: [
                          _VideoPreview(
                            detail: detail,
                            variantIndex: variantIndex,
                            onVariantChanged: (index) {
                              setState(() => _selectedVariantIndex = index);
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(15.w, 20.h, 15.w, 0),
                            child: _WorkDetailInfo(detail: detail),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 15.w,
              right: 15.w,
              bottom: 34.h,
              child: SafeArea(
                top: false,
                child: Obx(() {
                  final detail = controller.detail.value;
                  final enabled =
                      detail?.status == WorkStatus.succeeded &&
                      !controller.downloading.value;
                  return AppButton(
                    label: '下载视频',
                    loading: controller.downloading.value,
                    disabled: !enabled,
                    onPressed: () => controller.download(
                      context,
                      variantIndex: _safeVariantIndex(detail),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({
    required this.detail,
    required this.variantIndex,
    required this.onVariantChanged,
  });

  final WorkDetail detail;
  final int variantIndex;
  final ValueChanged<int> onVariantChanged;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _videoController;
  bool _initializing = false;
  String? _errorMessage;
  int _loadGeneration = 0;

  WorkDetail get detail => widget.detail;
  WorkVideoVariant? get _variant => detail.videoVariantAt(widget.variantIndex);
  bool get _canPlay => detail.status == WorkStatus.succeeded;
  String get _videoUrl =>
      _resolveMediaUrl(_variant?.videoUrl ?? detail.videoUrl);
  String get _coverUrl {
    final variantCover = _variant?.coverUrl.trim() ?? '';
    return _resolveMediaUrl(
      variantCover.isNotEmpty ? variantCover : detail.coverUrl,
    );
  }

  bool get _hasPlayableUrl => _isPlayableVideoUrl(_videoUrl);

  bool get _isInitialized =>
      _videoController != null && _videoController!.value.isInitialized;

  bool get _isPlaying => _isInitialized && _videoController!.value.isPlaying;

  @override
  void initState() {
    super.initState();
    if (_canPlay && _hasPlayableUrl) {
      unawaited(_initializeVideo());
    }
  }

  @override
  void didUpdateWidget(covariant _VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldVideoUrl =
        oldWidget.detail.videoVariantAt(oldWidget.variantIndex)?.videoUrl ??
        oldWidget.detail.videoUrl;
    final nextVideoUrl = _variant?.videoUrl ?? detail.videoUrl;
    if (oldVideoUrl == nextVideoUrl &&
        oldWidget.detail.status == detail.status) {
      return;
    }
    _loadGeneration++;
    _disposeVideo();
    if (_canPlay && _hasPlayableUrl) {
      unawaited(_initializeVideo());
    } else {
      setState(() {
        _initializing = false;
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _disposeVideo();
    super.dispose();
  }

  Future<void> _initializeVideo({bool autoPlay = false}) async {
    final url = _videoUrl;
    if (!_canPlay || !_isPlayableVideoUrl(url)) {
      return;
    }
    final generation = ++_loadGeneration;
    _disposeVideo();
    setState(() {
      _initializing = true;
      _errorMessage = null;
    });

    final controller = _createVideoController(url);
    try {
      await controller.initialize();
      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      controller.addListener(_handleVideoChanged);
      setState(() {
        _videoController = controller;
        _initializing = false;
      });
      if (autoPlay) {
        await controller.play();
      }
    } catch (_) {
      await controller.dispose();
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = '视频加载失败，点击重试';
      });
    }
  }

  void _handleVideoChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _disposeVideo() {
    final controller = _videoController;
    if (controller == null) {
      return;
    }
    controller.removeListener(_handleVideoChanged);
    _videoController = null;
    unawaited(controller.dispose());
  }

  Future<void> _togglePlay() async {
    if (_initializing) {
      return;
    }
    if (!_canPlay) {
      CustomToast.text('作品尚未生成完成');
      return;
    }
    if (!_hasPlayableUrl) {
      CustomToast.text('视频地址不存在');
      return;
    }
    if (_errorMessage != null || !_isInitialized) {
      await _initializeVideo(autoPlay: true);
      return;
    }

    final controller = _videoController!;
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }
    if (_isAtEnd(controller.value)) {
      await controller.seekTo(Duration.zero);
    }
    await controller.play();
  }

  Future<void> _openFullScreen() async {
    if (!_canPlay) {
      CustomToast.text('作品尚未生成完成');
      return;
    }
    if (!_hasPlayableUrl) {
      CustomToast.text('视频地址不存在');
      return;
    }
    await _videoController?.pause();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            _WorkVideoFullScreenPage(videoUrl: _videoUrl, coverUrl: _coverUrl),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300.h,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D2D1D), Color(0xFF071306)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_togglePlay()),
              child: _buildPreviewLayer(),
            ),
          ),
          Center(child: _buildCenterControl()),
          if (_isInitialized)
            Positioned(
              left: 15.w,
              right: 15.w,
              bottom: 13.h,
              child: _InlineVideoControls(
                controller: _videoController!,
                onTogglePlay: _togglePlay,
              ),
            ),
          Positioned(
            right: 10.w,
            bottom: 10.h,
            child: InkWell(
              onTap: _openFullScreen,
              borderRadius: BorderRadius.circular(15.r),
              child: Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 18.r,
                ),
              ),
            ),
          ),
          if (detail.status != WorkStatus.succeeded)
            Positioned(
              left: 15.w,
              top: 15.h,
              child: _DetailStatusBadge(status: detail.status),
            ),
          if (detail.videoVariants.length > 1)
            Positioned(
              left: 15.w,
              right: 15.w,
              top: 15.h,
              child: _VideoVariantSelector(
                variants: detail.videoVariants,
                selectedIndex: widget.variantIndex,
                onChanged: widget.onVariantChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewLayer() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPlaceholder(),
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            if (_isPlaying)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final coverUrl = _coverUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            width: 209.w,
            height: 300.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF283747), Color(0xFF182219)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: coverUrl.isEmpty
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black87],
              begin: Alignment.center,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterControl() {
    if (_initializing) {
      return SizedBox(
        width: 36.r,
        height: 36.r,
        child: CircularProgressIndicator(
          strokeWidth: 2.6.r,
          color: CustomTheme.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return InkWell(
        onTap: () => unawaited(_initializeVideo(autoPlay: true)),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ),
      );
    }

    if (_isPlaying) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => unawaited(_togglePlay()),
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        width: 48.r,
        height: 48.r,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            AppAssets.iconItemPlay,
            width: 32.r,
            height: 32.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _VideoVariantSelector extends StatelessWidget {
  const _VideoVariantSelector({
    required this.variants,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<WorkVideoVariant> variants;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: variants.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              height: 32.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? CustomTheme.primary
                    : Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: selected
                      ? CustomTheme.primary
                      : Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                variants[index].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InlineVideoControls extends StatelessWidget {
  const _InlineVideoControls({
    required this.controller,
    required this.onTogglePlay,
  });

  final VideoPlayerController controller;
  final Future<void> Function() onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => unawaited(onTogglePlay()),
            borderRadius: BorderRadius.circular(14.r),
            child: Icon(
              value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22.r,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            _formatVideoDuration(value.position),
            style: TextStyle(color: Colors.white, fontSize: 11.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.symmetric(vertical: 5.h),
              colors: VideoProgressColors(
                playedColor: CustomTheme.primary,
                bufferedColor: Colors.white.withValues(alpha: 0.35),
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            _formatVideoDuration(value.duration),
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

class _WorkVideoFullScreenPage extends StatefulWidget {
  const _WorkVideoFullScreenPage({required this.videoUrl, this.coverUrl});

  final String videoUrl;
  final String? coverUrl;

  @override
  State<_WorkVideoFullScreenPage> createState() =>
      _WorkVideoFullScreenPageState();
}

class _WorkVideoFullScreenPageState extends State<_WorkVideoFullScreenPage> {
  VideoPlayerController? _videoController;
  bool _initializing = true;
  String? _errorMessage;
  bool _showControls = true;
  bool _forceLandscape = false;
  Timer? _hideControlsTimer;

  bool get _isInitialized =>
      _videoController != null && _videoController!.value.isInitialized;

  bool get _isPlaying => _isInitialized && _videoController!.value.isPlaying;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideo());
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    final controller = _videoController;
    if (controller != null) {
      controller.removeListener(_handleVideoChanged);
      unawaited(controller.dispose());
    }
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final controller = _createVideoController(widget.videoUrl);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_handleVideoChanged);
      final isLandscape = controller.value.aspectRatio > 1;
      _forceLandscape = isLandscape;
      if (isLandscape) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      setState(() {
        _videoController = controller;
        _initializing = false;
      });
      await controller.play();
      _startHideControlsTimer();
    } catch (_) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = '视频加载失败';
      });
    }
  }

  void _handleVideoChanged() {
    if (!mounted) {
      return;
    }
    if (!_isPlaying) {
      _hideControlsTimer?.cancel();
      _showControls = true;
    }
    setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _togglePlay() async {
    if (!_isInitialized) {
      return;
    }
    final controller = _videoController!;
    if (controller.value.isPlaying) {
      await controller.pause();
      _hideControlsTimer?.cancel();
      if (mounted) {
        setState(() => _showControls = true);
      }
      return;
    }
    if (_isAtEnd(controller.value)) {
      await controller.seekTo(Duration.zero);
    }
    if (mounted) {
      setState(() => _showControls = true);
    }
    await controller.play();
    _startHideControlsTimer();
  }

  Future<void> _toggleOrientation() async {
    _forceLandscape = !_forceLandscape;
    await SystemChrome.setPreferredOrientations(
      _forceLandscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_togglePlay()),
              child: _buildVideoLayer(),
            ),
          ),
          if (_showControls) ...[
            Positioned(
              left: 14.w,
              top: 14.h,
              child: SafeArea(
                child: _RoundVideoButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: '返回',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Positioned(
              right: 14.w,
              top: 14.h,
              child: SafeArea(
                child: _RoundVideoButton(
                  icon: _forceLandscape
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  tooltip: _forceLandscape ? '退出横屏' : '横屏',
                  onTap: () => unawaited(_toggleOrientation()),
                ),
              ),
            ),
            if (_isInitialized && !_isPlaying)
              Center(
                child: _RoundVideoButton(
                  size: 62.r,
                  icon: Icons.play_arrow_rounded,
                  iconSize: 42.r,
                  tooltip: '播放',
                  onTap: () => unawaited(_togglePlay()),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _FullScreenVideoControls(
                  controller: _videoController,
                  onTogglePlay: _togglePlay,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_initializing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildFullScreenCover(),
          Center(
            child: SizedBox(
              width: 38.r,
              height: 38.r,
              child: CircularProgressIndicator(
                strokeWidth: 2.8.r,
                color: CustomTheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildFullScreenCover(),
          Center(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return _buildFullScreenCover();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildFullScreenCover() {
    final coverUrl = widget.coverUrl?.trim() ?? '';
    if (coverUrl.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D2D1D), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }
    return Image.network(
      coverUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

class _FullScreenVideoControls extends StatelessWidget {
  const _FullScreenVideoControls({
    required this.controller,
    required this.onTogglePlay,
  });

  final VideoPlayerController? controller;
  final Future<void> Function() onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final value = controller?.value;
    final initialized = value?.isInitialized == true;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (initialized)
            VideoProgressIndicator(
              controller!,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: VideoProgressColors(
                playedColor: CustomTheme.primary,
                bufferedColor: Colors.white.withValues(alpha: 0.35),
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
            )
          else
            Container(height: 3.h, color: Colors.white.withValues(alpha: 0.16)),
          SizedBox(height: 10.h),
          Row(
            children: [
              InkWell(
                onTap: initialized ? () => unawaited(onTogglePlay()) : null,
                borderRadius: BorderRadius.circular(16.r),
                child: Icon(
                  value?.isPlaying == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                _formatVideoDuration(value?.position ?? Duration.zero),
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
              Text(
                ' / ${_formatVideoDuration(value?.duration ?? Duration.zero)}',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundVideoButton extends StatelessWidget {
  const _RoundVideoButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size,
    this.iconSize,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 40.r;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: iconSize ?? 20.r),
        ),
      ),
    );
  }
}

VideoPlayerController _createVideoController(String videoUrl) {
  final uri = Uri.tryParse(videoUrl);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return VideoPlayerController.networkUrl(uri);
  }
  if (uri != null && uri.scheme == 'file') {
    return VideoPlayerController.file(File.fromUri(uri));
  }
  return VideoPlayerController.file(File(videoUrl));
}

bool _isPlayableVideoUrl(String videoUrl) {
  final value = videoUrl.trim();
  if (value.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(value);
  if (uri == null) {
    return false;
  }
  if (uri.hasScheme) {
    return uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'file';
  }
  return File(value).existsSync();
}

String _resolveMediaUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return value;
  }
  final localFile = File(value);
  if (localFile.existsSync()) {
    return value;
  }
  final baseUrl = HttpService.to.baseUrl.trim();
  if (baseUrl.isEmpty) {
    return value;
  }
  return Uri.parse(baseUrl).resolve(value).toString();
}

bool _isAtEnd(VideoPlayerValue value) {
  return value.duration > Duration.zero && value.position >= value.duration;
}

String _formatVideoDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  String two(int value) => value.toString().padLeft(2, '0');
  if (safe.inHours > 0) {
    return '${two(safe.inHours)}:${two(safe.inMinutes.remainder(60))}:${two(safe.inSeconds.remainder(60))}';
  }
  return '${two(safe.inMinutes.remainder(60))}:${two(safe.inSeconds.remainder(60))}';
}

class _WorkDetailInfo extends StatelessWidget {
  const _WorkDetailInfo({required this.detail});

  final WorkDetail detail;

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      detail.durationText,
      ...detail.params.values,
    ].where((tag) => tag.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 9.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 8.h,
          children: tags.map((tag) {
            return Container(
              height: 23.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                tag,
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 14.h),
        Text(
          '创建时间 ${detail.createdAtText}',
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        if (detail.expireAtText != null) ...[
          SizedBox(height: 8.h),
          Text(
            detail.expireAtText!,
            style: TextStyle(color: CustomTheme.primary, fontSize: 12.sp),
          ),
        ],
        if (detail.status != WorkStatus.succeeded) ...[
          SizedBox(height: 18.h),
          _DetailStatePanel(detail: detail),
        ],
      ],
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.status});

  final WorkStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String get _label {
    return switch (status) {
      WorkStatus.draft => '草稿',
      WorkStatus.queued => '排队中',
      WorkStatus.generating => '生成中',
      WorkStatus.succeeded => '已完成',
      WorkStatus.failed => '生成失败',
      WorkStatus.expired => '已过期',
    };
  }
}

class _DetailStatePanel extends StatelessWidget {
  const _DetailStatePanel({required this.detail});

  final WorkDetail detail;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (detail.status) {
      WorkStatus.draft => (AppAssets.iconEdit, '草稿作品', '草稿继续编辑策略待确认，当前保留详情预览。'),
      WorkStatus.queued => (AppAssets.iconCalendar, '排队中', '任务已提交，正在等待生成资源。'),
      WorkStatus.generating => (
        AppAssets.iconListening,
        '生成中',
        '作品正在生成，完成后可播放和下载。',
      ),
      WorkStatus.failed => (AppAssets.iconCaution, '生成失败', '任务失败原因和重试策略待后端确认。'),
      WorkStatus.expired => (
        AppAssets.iconWarning,
        '作品已过期',
        '作品当前保留 7 天，过期策略以后端为准。',
      ),
      WorkStatus.succeeded => (AppAssets.iconCheckAgreement, '已完成', '作品已生成完成。'),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            icon,
            width: 24.r,
            height: 24.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
