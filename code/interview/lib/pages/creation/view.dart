part of 'index.dart';

class CreationPage extends StatefulWidget {
  const CreationPage({super.key});

  @override
  State<CreationPage> createState() => _CreationPageState();
}

class _CreationPageState extends State<CreationPage> {
  late final CreationController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(CreationController());
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
          '视频解说',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundImage: AssetImage(AppAssets.imageCreateBg),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 164.h),
                children: [
                  const _CreationTip(),
                  SizedBox(height: 20.h),
                  Obx(
                    () => _MaterialPanel(
                      selected: controller.selectedMaterials,
                      summary: controller.selectedSummary,
                      canAdd: controller.selectedMaterials.length < 10,
                      onAdd: () => controller.pickVideos(context),
                      onPreview: (material) =>
                          controller.previewVideo(context, material),
                      onDelete: controller.removeVideo,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Obx(
                    () => _CreationOptions(
                      styleName: controller.selectedStyle?.name,
                      voiceName: controller.selectedVoice?.name,
                      speed: controller.store.speed.value,
                      speedOptions: controller.speedOptions,
                      onStyleTap: () => controller.openStyleSelector(context),
                      onVoiceTap: () => controller.openVoiceSelector(context),
                      onMoreTap: () => controller.openMoreSettings(context),
                      onSpeedChanged: controller.setSpeed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 15.w,
            right: 15.w,
            bottom: 34.h,
            child: _GenerateButton(
              submitting: controller.submitting,
              pageState: () => controller.pageState,
              onTap: () => controller.handleGenerate(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }
}

class _CreationTip extends StatelessWidget {
  const _CreationTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(17.r),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.iconCaution,
            width: 20.r,
            height: 20.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '生成视频按时长计费，20积分/分钟',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: const Color(0xFFF6FFFF), fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}

/// 视频素材选择区域，根据是否已有视频切换上传空态和已选列表。
class _MaterialPanel extends StatelessWidget {
  const _MaterialPanel({
    required this.selected,
    required this.summary,
    required this.canAdd,
    required this.onAdd,
    required this.onPreview,
    required this.onDelete,
  });

  /// 当前已选择并显示在面板中的视频素材。
  final List<CreationMaterial> selected;

  /// 面板底部的视频数量和总时长摘要。
  final String summary;

  /// 是否还允许继续添加视频。
  final bool canAdd;

  /// 点击上传/新增视频时触发的回调。
  final VoidCallback onAdd;

  /// 点击视频缩略图时触发的本地预览回调。
  final ValueChanged<CreationMaterial> onPreview;

  /// 点击视频右上角删除按钮时触发的移除回调。
  final ValueChanged<CreationMaterial> onDelete;

  @override
  Widget build(BuildContext context) {
    if (selected.isEmpty) {
      return _UploadPanel(onTap: onAdd);
    }

    return _SelectedMaterialPanel(
      selected: selected,
      summary: summary,
      canAdd: canAdd,
      onAdd: onAdd,
      onPreview: onPreview,
      onDelete: onDelete,
    );
  }
}

/// 已选视频列表面板，负责按 Figma 的 74 方形网格展示视频和新增入口。
class _SelectedMaterialPanel extends StatelessWidget {
  const _SelectedMaterialPanel({
    required this.selected,
    required this.summary,
    required this.canAdd,
    required this.onAdd,
    required this.onPreview,
    required this.onDelete,
  });

  /// 已选择的视频素材列表。
  final List<CreationMaterial> selected;

  /// 底部摘要文案。
  final String summary;

  /// 是否展示继续添加视频的入口。
  final bool canAdd;

  /// 新增视频入口点击回调。
  final VoidCallback onAdd;

  /// 视频缩略图点击预览回调。
  final ValueChanged<CreationMaterial> onPreview;

  /// 视频删除按钮点击回调。
  final ValueChanged<CreationMaterial> onDelete;

  @override
  Widget build(BuildContext context) {
    final itemCount = selected.length + (canAdd ? 1 : 0);
    final rowCount = ((itemCount + 3) ~/ 4).clamp(1, 3);
    final tileSize = 74.r;
    final gridHeight = rowCount * tileSize + (rowCount - 1) * 10.h;
    final panelHeight = (gridHeight + 151.h).clamp(230.h, 329.h).toDouble();

    return Container(
      height: panelHeight,
      padding: EdgeInsets.all(1.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF82F571), Color(0xFFD9FB5C), Color(0xFF7BF788)],
          stops: [0, 0.4, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3E5311), Color(0xFF5F8B0E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            CustomPaint(painter: _UploadPanelVignettePainter()),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 18.h, 10.w, 14.h),
              child: Column(
                children: [
                  SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: itemCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        if (index == selected.length) {
                          return _AddMaterialTile(onTap: onAdd);
                        }
                        final item = selected[index];
                        return _SelectedMaterialTile(
                          item: item,
                          onTap: () => onPreview(item),
                          onDelete: () => onDelete(item),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Divider(
                      height: 1.h,
                      thickness: 1.h,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppAssets.iconWarning,
                          width: 14.r,
                          height: 14.r,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 230.h,
        padding: EdgeInsets.all(1.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF82F571), Color(0xFFD9FB5C), Color(0xFF7BF788)],
            stops: [0, 0.4, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3E5311), Color(0xFF5F8B0E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              CustomPaint(painter: _UploadPanelVignettePainter()),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.iconVideo,
                    width: 54.r,
                    height: 54.r,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    height: 42.h,
                    width: 140.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF2F865), Color(0xFF6BF775)],
                      ),
                      borderRadius: BorderRadius.circular(21.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAFFB66).withValues(alpha: 0.5),
                          blurRadius: 16.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppAssets.iconAddVideo,
                          width: 14.r,
                          height: 14.r,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '上传视频',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppAssets.iconWarning,
                        width: 14.r,
                        height: 14.r,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        '单视频10秒-30分钟，最多添加10个',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10.sp,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 复刻 Figma 上传卡片中央的黑色聚焦暗场，避免空态卡片看起来过平。
class _UploadPanelVignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromLTWH(
        -0.194 * size.width,
        -0.270 * size.height,
        1.391 * size.width,
        1.891 * size.height,
      ),
      paint,
    );

    paint.color = Colors.black.withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromLTWH(
        -0.078 * size.width,
        -0.113 * size.height,
        1.159 * size.width,
        1.575 * size.height,
      ),
      paint,
    );

    paint.color = Colors.black;
    canvas.drawOval(
      Rect.fromLTWH(
        -0.041 * size.width,
        -0.206 * size.height,
        1.084 * size.width,
        1.206 * size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _UploadPanelVignettePainter oldDelegate) {
    return false;
  }
}

/// 单个已选视频 item，支持点击预览和右上角直接删除。
class _SelectedMaterialTile extends StatelessWidget {
  const _SelectedMaterialTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  /// 当前 item 对应的视频素材。
  final CreationMaterial item;

  /// 点击缩略图主体时触发的视频预览回调。
  final VoidCallback onTap;

  /// 点击右上角删除按钮时触发的删除回调。
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    final loading = item.status == MaterialStatus.processing;
    final failed = item.status == MaterialStatus.failed;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF263D32), Color(0xFF0B100C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _MaterialThumbnail(url: item.thumbUrl)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: loading ? 0.62 : 0.22),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              if (loading)
                Center(
                  child: SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.r,
                      color: CustomTheme.primary,
                    ),
                  ),
                )
              else if (failed)
                Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: CustomTheme.danger,
                    size: 22.r,
                  ),
                )
              else
                Center(
                  child: Image.asset(
                    AppAssets.iconItemPlay,
                    width: 20.r,
                    height: 20.r,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              if (loading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8.h,
                  child: Text(
                    '读取中',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Positioned(
                top: 3.r,
                right: 3.r,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: SizedBox.square(
                    dimension: 24.r,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(
                        AppAssets.iconItemDelete,
                        width: 18.r,
                        height: 18.r,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
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

class _MaterialThumbnail extends StatelessWidget {
  const _MaterialThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final value = url.trim();
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    final file = File(value);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    if (value.startsWith('http')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _AddMaterialTile extends StatelessWidget {
  const _AddMaterialTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Image.asset(
            AppAssets.iconItemAdd,
            width: 24.r,
            height: 24.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _CreationOptions extends StatelessWidget {
  const _CreationOptions({
    required this.styleName,
    required this.voiceName,
    required this.speed,
    required this.speedOptions,
    required this.onStyleTap,
    required this.onVoiceTap,
    required this.onMoreTap,
    required this.onSpeedChanged,
  });

  final String? styleName;
  final String? voiceName;
  final double speed;
  final List<double> speedOptions;
  final VoidCallback onStyleTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onMoreTap;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OptionRow(title: '解说风格', value: styleName, onTap: onStyleTap),
        SizedBox(height: 10.h),
        _OptionRow(title: '配音角色', value: voiceName, onTap: onVoiceTap),
        SizedBox(height: 10.h),
        _SpeedPanel(
          speed: speed,
          speedOptions: speedOptions,
          onSpeedChanged: onSpeedChanged,
        ),
        SizedBox(height: 10.h),
        _OptionRow(title: '更多设置', onTap: onMoreTap),
      ],
    );
  }
}

/// 创作设置中的通用选项行。
///
/// 右侧 value 和箭头必须作为一个 trailing 区域贴到最右侧，和 Figma 对齐。
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.title, this.value, required this.onTap});

  /// 左侧选项标题。
  final String title;

  /// 右侧当前选中的展示值，为空时只展示箭头。
  final String? value;

  /// 点击整行时打开对应选择弹层或设置页。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: _glassDecoration(radius: 18.r),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            if (value != null) ...[
              // 用最大宽度限制右侧文案，让左侧 Expanded 吃掉空白，
              // 保证“选中值 + 箭头”整体始终贴在行尾。
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 180.w),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: CustomTheme.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Image.asset(
              AppAssets.iconBackRight,
              width: 16.r,
              height: 16.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedPanel extends StatelessWidget {
  const _SpeedPanel({
    required this.speed,
    required this.speedOptions,
    required this.onSpeedChanged,
  });

  final double speed;
  final List<double> speedOptions;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 87.h,
      padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 10.h),
      decoration: _glassDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '语速',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                color: const Color(0xFFCCCCCC).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: speedOptions.map((option) {
                  final selected = (speed - option).abs() < 0.01;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onSpeedChanged(option),
                      borderRadius: BorderRadius.circular(10.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFECFF62),
                                    Color(0xFFC1F869),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${option.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontSize: 12.sp,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.submitting,
    required this.pageState,
    required this.onTap,
  });

  final RxBool submitting;
  final ViewState Function() pageState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = submitting.value;
      final disabled = pageState() != ViewState.success;
      final enabled = !loading && !disabled;

      return Opacity(
        opacity: disabled ? 0.48 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Container(
            height: 50.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF82F571),
                  Color(0xFFD9FB5C),
                  Color(0xFF2BDC3D),
                ],
                stops: [0, 0.4, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: loading
                  ? const _GenerateButtonLoading()
                  : const _GenerateButtonLabel(),
            ),
          ),
        ),
      );
    });
  }
}

class _GenerateButtonLabel extends StatelessWidget {
  const _GenerateButtonLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      '立即生成',
      key: const ValueKey<String>('generate-label'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GenerateButtonLoading extends StatelessWidget {
  const _GenerateButtonLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('generate-loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18.r,
          height: 18.r,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '生成中',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

BoxDecoration _glassDecoration({required double radius}) {
  return BoxDecoration(
    color: const Color(0xFF999999).withValues(alpha: 0.1),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    borderRadius: BorderRadius.circular(radius),
  );
}
