part of 'index.dart';

class HomeCaseDetailPage extends StatefulWidget {
  const HomeCaseDetailPage({super.key, required this.caseId, this.initialCase});

  final String caseId;
  final HomeCase? initialCase;

  @override
  State<HomeCaseDetailPage> createState() => _HomeCaseDetailPageState();
}

class _HomeCaseDetailPageState extends State<HomeCaseDetailPage>
    with RouteAware, WidgetsBindingObserver {
  late HomeCase _case = widget.initialCase ?? _emptyCase(widget.caseId);
  VideoPlayerController? _videoController;
  String _initializedVideoUrl = '';
  bool _loading = false;
  bool _videoReady = false;
  bool _videoInitializing = false;
  String? _errorMessage;
  String? _videoErrorMessage;
  PageRoute<dynamic>? _route;

  String get _coverUrl => _resolveHomeCaseMediaUrl(_case.coverUrl);
  String get _videoUrl => _resolveHomeCaseMediaUrl(_case.videoUrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadDetail());
    if (_videoUrl.isNotEmpty) {
      unawaited(_initializeVideo());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        CustomRouter.observer.unsubscribe(this);
      }
      _route = route;
      CustomRouter.observer.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _pausePlayback();
  }

  @override
  void didPop() {
    _pausePlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pausePlayback();
    }
  }

  @override
  void dispose() {
    CustomRouter.observer.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pausePlayback();
    unawaited(_videoController?.dispose());
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final caseId = widget.caseId.trim();
    if (caseId.isEmpty || Get.find<ConfigStore>().mockEnabled.value) {
      return;
    }
    unawaited(_trackUsage(caseId));
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final detail = await HomeAPI.fetchCaseDetail(caseId);
      if (!mounted) {
        return;
      }
      setState(() {
        _case = detail;
      });
      if (_videoUrl.isNotEmpty) {
        unawaited(_initializeVideo());
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.userMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '案例详情加载失败');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _trackUsage(String caseId) async {
    try {
      await HomeAPI.useCase(caseId);
    } catch (_) {
      // 统计失败不影响播放页打开和详情加载。
    }
  }

  Future<void> _initializeVideo({bool autoPlay = false}) async {
    final videoUrl = _videoUrl;
    if (videoUrl.isEmpty) {
      return;
    }
    if (_initializedVideoUrl == videoUrl && _videoController != null) {
      if (autoPlay) {
        await _videoController!.play();
      }
      return;
    }
    final uri = Uri.tryParse(videoUrl);
    if (uri == null || !uri.hasScheme) {
      setState(() => _videoErrorMessage = '视频地址无效');
      return;
    }

    setState(() {
      _videoInitializing = true;
      _videoReady = false;
      _videoErrorMessage = null;
    });

    final previous = _videoController;
    final next = VideoPlayerController.networkUrl(uri);
    try {
      await next.initialize();
      await next.setLooping(false);
      if (!mounted) {
        await next.dispose();
        return;
      }
      if (autoPlay) {
        await next.play();
      }
      setState(() {
        _videoController = next;
        _initializedVideoUrl = videoUrl;
        _videoReady = true;
        _videoInitializing = false;
      });
      unawaited(previous?.dispose());
    } catch (_) {
      await next.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _videoReady = false;
        _videoInitializing = false;
        _videoErrorMessage = '视频加载失败';
      });
    }
  }

  Future<void> _togglePlay() async {
    final controller = _videoController;
    if (controller == null || !_videoReady) {
      await _initializeVideo(autoPlay: true);
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _pausePlayback() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final isPlaying = controller?.value.isPlaying == true;

    return Scaffold(
      backgroundColor: CustomTheme.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF12350E), CustomTheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(onBack: () => CustomRouter.popOrMain(context)),
              Expanded(
                child: _PlayerArea(
                  coverUrl: _coverUrl,
                  videoController: controller,
                  videoReady: _videoReady,
                  videoInitializing: _videoInitializing,
                  videoErrorMessage: _videoErrorMessage,
                  isPlaying: isPlaying,
                  onTogglePlay: () => unawaited(_togglePlay()),
                ),
              ),
              _BottomPanel(
                item: _case,
                loading: _loading,
                errorMessage: _errorMessage,
                onRetry: () => unawaited(_loadDetail()),
                onCreate: () {
                  _pausePlayback();
                  context.pushNamed(RouteName.creationVideo);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static HomeCase _emptyCase(String caseId) {
    return HomeCase(
      id: caseId,
      title: '案例加载中',
      category: '',
      categoryCode: '',
      displayLabel: '',
      durationText: '',
      coverUrl: '',
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56.h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22.r),
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PlayerArea extends StatelessWidget {
  const _PlayerArea({
    required this.coverUrl,
    required this.videoController,
    required this.videoReady,
    required this.videoInitializing,
    required this.videoErrorMessage,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  final String coverUrl;
  final VideoPlayerController? videoController;
  final bool videoReady;
  final bool videoInitializing;
  final String? videoErrorMessage;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.max(0.0, constraints.maxWidth - 48.w);
        final maxHeight = math.max(0.0, constraints.maxHeight - 12.h);
        final playerWidth = math.min(maxWidth, maxHeight * 9 / 16);
        final playerHeight = math.min(maxHeight, playerWidth * 16 / 9);
        final width = playerHeight * 9 / 16;

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTogglePlay,
            child: Container(
              width: width,
              height: playerHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: CustomTheme.primary.withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 28.r,
                    offset: Offset(0, 12.h),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: _PlayerBackground(coverUrl: coverUrl)),
                  if (videoReady && videoController != null)
                    Positioned.fill(
                      child: _FittedVideoPlayer(controller: videoController!),
                    ),
                  if (videoInitializing)
                    SizedBox(
                      width: 34.r,
                      height: 34.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.r,
                        color: CustomTheme.primary,
                      ),
                    )
                  else
                    _PlayButton(isPlaying: isPlaying),
                  if (videoErrorMessage != null)
                    Positioned(
                      left: 14.w,
                      right: 14.w,
                      bottom: 14.h,
                      child: Text(
                        videoErrorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FittedVideoPlayer extends StatelessWidget {
  const _FittedVideoPlayer({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final width = size.width <= 0 ? 9.0 : size.width;
    final height = size.height <= 0 ? 16.0 : size.height;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: width,
        height: height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _PlayerBackground extends StatelessWidget {
  const _PlayerBackground({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }
    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const ColoredBox(color: Colors.black);
      },
      errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isPlaying ? 0 : 1,
      duration: const Duration(milliseconds: 160),
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36.r),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.item,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onCreate,
  });

  final HomeCase item;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 18.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _DetailError(message: errorMessage!, onRetry: onRetry),
            )
          else if (loading)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: LinearProgressIndicator(
                minHeight: 2.h,
                color: CustomTheme.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          _StyleCard(item: item),
          SizedBox(height: 16.h),
          AppButton(
            label: '去创作',
            icon: Icons.auto_fix_high_rounded,
            onPressed: onCreate,
            height: 56.h,
            backgroundColor: CustomTheme.primary,
            foregroundColor: Colors.black,
            borderRadius: 14.r,
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomTheme.danger.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: CustomTheme.danger,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '$message，点击重试',
                  style: TextStyle(
                    color: CustomTheme.danger,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.item});

  final HomeCase item;

  @override
  Widget build(BuildContext context) {
    final styleName = item.styleName.trim().isEmpty
        ? '解说风格'
        : item.styleName.trim();
    final applicable = item.styleApplicableText.trim().isEmpty
        ? '适合快速进入主题的案例视频。'
        : item.styleApplicableText.trim();
    final explanation = item.styleExplanationText.trim().isEmpty
        ? '先观看案例效果，再进入创作页选择相近风格。'
        : item.styleExplanationText.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: CustomTheme.surfaceHigh.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '解说风格',
                style: TextStyle(
                  color: CustomTheme.primary,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  styleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 24.h, color: Colors.white.withValues(alpha: 0.08)),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '适用：',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: applicable),
                const TextSpan(text: '\n'),
                const TextSpan(
                  text: '解释：',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: explanation),
              ],
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

String _resolveHomeCaseMediaUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return value;
  }
  final baseUrl = HttpService.to.baseUrl.trim();
  if (baseUrl.isEmpty) {
    return value;
  }
  return Uri.parse(baseUrl).resolve(value).toString();
}
