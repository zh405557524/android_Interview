part of 'index.dart';

/// 视频解说创作页的业务与状态控制类。
///
/// 参考 `clip-flutter` 的视频上传控制器风格，Controller 直接编排权限、
/// 系统相册、弹层、路由、Toast 和上传生成流程；子组件仍只接收值与回调。
final class CreationController extends GetxController {
  /// 前端允许上传的单个视频最大时长。
  ///
  /// 超出该时长的视频会在本地元信息读取完成后被移除，不创建 quick batch，
  /// 也不会进入百度上传链路。
  static const Duration maxUploadVideoDuration = Duration(minutes: 30);

  /// 创作草稿的跨页面状态仓库。
  final CreationStore store = Get.find<CreationStore>();

  /// 当前用户状态仓库，用于判断登录态、积分余额等业务条件。
  final UserStore userStore = Get.find<UserStore>();

  /// 创作配置后台加载状态；页面不再因为它显示整页 loading。
  final RxBool loading = false.obs;

  /// 上传/提交链路运行中状态。
  final RxBool submitting = false.obs;

  /// 创作配置加载失败时记录的错误文案；页面保持正常展示。
  final RxnString errorMessage = RxnString();

  /// 上传/提交弹层展示的进度快照。
  final Rx<CreationGenerationProgress> generationProgress =
      const CreationGenerationProgress.idle().obs;

  /// 当前页面已选择或正在读取的本地视频素材。
  final RxList<CreationMaterial> materials = <CreationMaterial>[].obs;

  /// 当前批次锁定的作品类型。
  ///
  /// 第一个读取完成的视频会根据时长锁定类型；后续视频只允许加入同类型规则
  /// 覆盖的时长范围。全部视频删除后会清空，下一次选择重新判定。
  final Rxn<WorkType> selectedWorkType = Rxn<WorkType>();

  /// 后端返回的真实创作风格配置。
  final RxList<CreationStyle> styles = <CreationStyle>[].obs;

  /// 后端返回的真实配音角色配置。
  final RxList<VoiceRole> voices = <VoiceRole>[].obs;

  /// 创作配置服务，负责缓存风格与配音数据。
  final CreationConfigService configService =
      Get.isRegistered<CreationConfigService>()
      ? Get.find<CreationConfigService>()
      : Get.put(CreationConfigService(), permanent: true);

  /// 系统相册视频选择器。
  final ImagePicker _picker = ImagePicker();

  /// 当前上传弹层正在处理的后端批次，失败重试时用于复用进度。
  QuickGenerationBatch? _activeBatch;

  /// 当前上传弹层使用的幂等键，避免重试时重复创建批次。
  String? _activeIdempotencyKey;

  /// 页面可选的语速倍率。
  final List<double> speedOptions = const <double>[0.8, 1.0, 1.2, 1.5];

  /// 页面可选的配音情绪。
  final List<String> emotionOptions = const <String>[
    '通用',
    '开心',
    '惊讶',
    '厌恶',
    '悲伤',
    '生气',
    '害怕',
  ];

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitialData());
  }

  /// 当前页面整体状态固定为成功，配置加载失败也不遮挡视频解说主界面。
  ViewState get pageState => ViewState.success;

  /// 当前被选中的视频素材列表，顺序与选择顺序一致。
  List<CreationMaterial> get selectedMaterials {
    final selectedIds = store.selectedMaterialIds.toSet();
    return materials.where((item) => selectedIds.contains(item.id)).toList();
  }

  /// 当前选中的创作风格。
  CreationStyle? get selectedStyle {
    return _firstWhereOrNull<CreationStyle>(
      styles,
      (item) => item.id == store.selectedStyleId.value,
    );
  }

  /// 当前选中的配音角色。
  VoiceRole? get selectedVoice {
    return _firstWhereOrNull<VoiceRole>(
      voices,
      (item) => item.id == store.selectedVoiceRoleId.value,
    );
  }

  /// 已选视频总时长，单位秒。
  int get totalDurationSeconds {
    return selectedMaterials.fold<int>(
      0,
      (previous, item) => previous + item.durationSeconds,
    );
  }

  /// 视频选择区域底部摘要文案。
  String get selectedSummary {
    final count = selectedMaterials.length;
    if (count == 0) {
      return '短剧10秒-20分钟，电视剧10-80分钟，电影60分钟以上';
    }
    final type = selectedWorkType.value;
    final typeText = type == null ? '' : '、${type.label}';
    return '已选择$count/10个视频$typeText、共${_formatMinutes(totalDurationSeconds)}分钟';
  }

  /// 当前页面是否具备点击生成的最小条件。
  bool get canGenerate => selectedMaterials.isNotEmpty;

  /// 静默加载创作页需要的真实配置。
  Future<bool> loadInitialData({bool force = false}) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await configService.load(force: force);
      _syncConfigFromService();
      _ensureDefaultSelection();
      errorMessage.value = configService.errorMessage.value;
      return loaded;
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
      return false;
    } catch (_) {
      errorMessage.value = '创作配置加载失败';
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// 替换当前选中的素材 ID 列表，最多保留 10 个。
  void replaceSelection(List<String> ids) {
    store.selectedMaterialIds.assignAll(_uniqueIds(ids).take(10));
    _syncLockedWorkTypeAfterSelectionChanged();
  }

  /// 选择指定创作风格。
  void selectStyle(String id) {
    store.selectedStyleId.value = id;
  }

  /// 选择指定配音角色。
  void selectVoice(String id) {
    store.selectedVoiceRoleId.value = id;
  }

  /// 选择配音情绪。
  void selectEmotion(String value) {
    store.selectedEmotion.value = value;
  }

  /// 设置生成视频的语速倍率。
  void setSpeed(double value) {
    store.speed.value = value;
  }

  /// 设置是否生成多样化版本。
  void setDiversifiedVersionsEnabled(bool value) {
    store.diversifiedVersionsEnabled.value = value;
  }

  /// 发起本地视频选择流程。
  ///
  /// 参考视频上传页：先展示权限说明并申请视频权限，再打开系统相册；
  /// Android 单选追加以便用户预览视频，iOS 保留多选体验。
  Future<void> pickVideos(BuildContext context) async {
    final remaining = 10 - store.selectedMaterialIds.length;
    if (remaining <= 0) {
      _showToast('最多添加10个视频');
      return;
    }

    final hasPermission = await Access.videos(context);
    if (!hasPermission || !context.mounted) {
      return;
    }

    AppLogger.info('[Creation] open album video picker');
    List<XFile> pickedVideos;
    try {
      pickedVideos = await _pickVideosFromGallery(
        context,
        limit: remaining,
        maxDuration: maxUploadVideoDuration,
      );
    } on MissingPluginException catch (error) {
      AppLogger.error('[Creation] image_picker missing plugin', error);
      _showToast('文件选择器未初始化，请完全重启应用后再试');
      return;
    } on PlatformException catch (error) {
      AppLogger.error('[Creation] video picker platform error', error);
      if (context.mounted) {
        _handleVideoPickerException(context, error);
      } else {
        _showToast('无法打开视频选择器');
      }
      return;
    } catch (error) {
      AppLogger.error('[Creation] video picker failed', error);
      _showToast('无法打开视频选择器');
      return;
    }

    _appendPickedVideos(pickedVideos, remaining);
  }

  /// 预览已选择的本地视频素材。
  ///
  /// 这里只允许打开读取完成且仍存在本地文件的视频；读取中、读取失败或文件已被
  /// 系统清理时，直接给出提示，避免播放器进入空白状态。
  Future<void> previewVideo(
    BuildContext context,
    CreationMaterial material,
  ) async {
    if (material.status == MaterialStatus.processing) {
      _showToast('视频读取中，请稍后再看');
      return;
    }
    if (material.status == MaterialStatus.failed) {
      _showToast('视频读取失败，请重新选择');
      return;
    }

    final path = material.filePath?.trim() ?? '';
    if (path.isEmpty) {
      _showToast('无法读取视频路径');
      return;
    }

    final file = File(path);
    if (!file.existsSync()) {
      _showToast('视频文件不存在，请重新选择');
      return;
    }

    await CreationVideoPreviewDialog.show(
      context: context,
      file: file,
      title: material.name,
    );
  }

  /// 从当前创作列表中移除一个已选择的视频素材。
  ///
  /// 这里只清理页面状态和选中关系，不删除系统相册或本地临时文件。
  void removeVideo(CreationMaterial material) {
    _removePickedVideo(material.id);
  }

  /// 打开风格选择弹层，并在用户确认后更新创作草稿。
  Future<void> openStyleSelector(BuildContext context) async {
    if (styles.isEmpty &&
        !await _loadConfigWithDialog(context, needStyles: true)) {
      return;
    }
    final selected = selectedStyle;
    if (selected == null || styles.isEmpty) {
      _showToast('暂无可用解说风格');
      return;
    }
    if (!context.mounted) {
      return;
    }
    final styleId = await showCreationStyleSheet(
      context,
      styles: styles.toList(growable: false),
      initialMode: selected.mode,
      initialStyleId: store.selectedStyleId.value,
    );
    if (styleId?.trim().isNotEmpty == true) {
      selectStyle(styleId!);
    }
  }

  /// 打开配音选择弹层，并在用户确认后更新角色和情绪。
  Future<void> openVoiceSelector(BuildContext context) async {
    if (voices.isEmpty &&
        !await _loadConfigWithDialog(context, needVoices: true)) {
      return;
    }
    if (voices.isEmpty) {
      _showToast('暂无可用配音角色');
      return;
    }
    if (!context.mounted) {
      return;
    }
    final result = await showCreationVoiceSheet(
      context,
      voices: voices.toList(growable: false),
      emotions: emotionOptions,
      initialVoiceId: store.selectedVoiceRoleId.value,
      initialEmotion: store.selectedEmotion.value,
    );
    if (result == null) {
      return;
    }
    selectVoice(result.voiceId);
    selectEmotion(result.emotion);
  }

  /// 打开更多设置弹层，并在用户确认后更新草稿设置。
  Future<void> openMoreSettings(BuildContext context) async {
    final result = await showCreationMoreSettingsSheet(
      context,
      initialDiversifiedVersionsEnabled: store.diversifiedVersionsEnabled.value,
    );
    if (result == null) {
      return;
    }
    setDiversifiedVersionsEnabled(result.diversifiedVersionsEnabled);
  }

  /// 计算本地积分预估，并在无法生成时给出用户可读提示。
  GenerationEstimate? localEstimate() {
    if (!canGenerate) {
      _showToast('请先上传或选择视频');
      return null;
    }
    if (selectedMaterials.any(
      (item) => item.status == MaterialStatus.processing,
    )) {
      _showToast('视频信息读取中，请稍后再生成');
      return null;
    }
    if (selectedMaterials.any((item) => item.status == MaterialStatus.failed)) {
      _showToast('视频读取失败，请重新选择视频');
      return null;
    }
    final minutes = totalDurationSeconds <= 0
        ? 1
        : (totalDurationSeconds / 60).ceil();
    final pointCost = minutes * 20;
    return GenerationEstimate(
      pointCost: pointCost,
      enough: userStore.points.value >= pointCost,
      message: '预计消耗 $pointCost 积分',
    );
  }

  /// 处理“立即生成”的完整前端业务流程。
  Future<void> handleGenerate(BuildContext context) async {
    if (!userStore.isLoggedIn) {
      context.pushNamed(RouteName.login);
      return;
    }

    final estimate = localEstimate();
    if (estimate == null) {
      return;
    }
    if (!await _ensureRequiredConfigForGenerate(context)) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (!estimate.enough) {
      final shouldUpgrade = await showCreationEntitlementDialog(context);
      if (shouldUpgrade == true && context.mounted) {
        context.pushNamed(RouteName.membership);
      }
      return;
    }

    if (!context.mounted) {
      return;
    }
    final confirmed = await showCreationPointsConfirmDialog(context, estimate);
    if (confirmed != true || !context.mounted) {
      return;
    }

    final batch = await showCreationUploadProgressDialog(
      context,
      progress: generationProgress,
      onStart: generateWithProgress,
      onRetry: retryGeneration,
    );
    if (batch == null || !context.mounted) {
      return;
    }
    _showToast('作品已创建，可在作品中查看生成进度');
    finishCreatedWork(context);
  }

  /// 完成作品创建后的跨页面收尾。
  ///
  /// 先通知“我的作品”刷新列表，再切换到底部作品 Tab，最后关闭当前创作页。
  /// 这样用户返回主页面时可以直接看到最新作品列表。
  void finishCreatedWork(BuildContext context) {
    if (Get.isRegistered<EventService>()) {
      Get.find<EventService>().emit(const WorksListRefreshRequested());
    }
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().showWorksTab();
    }
    CustomRouter.popOrMain(context);
  }

  /// 回到主页或关闭当前创作页。
  void openMain(BuildContext context) {
    CustomRouter.popOrMain(context);
  }

  /// 兼容旧调用点的生成入口。
  ///
  /// 实际流程统一收敛到 [generateWithProgress]，这样确认积分、重试和测试都走
  /// 同一套真实上传逻辑。
  Future<QuickGenerationBatch?> createQuickBatch() async {
    return generateWithProgress();
  }

  /// 从失败点重新发起提交。
  ///
  /// 仍有效的批次会复用原有 idempotency key 和已创建的批次；如果后端已经进入
  /// 失败、取消、过期等终态，则重新创建一批上传任务。
  Future<QuickGenerationBatch?> retryGeneration() async {
    if (_activeBatch == null || _isTerminalFailure(_activeBatch!.status)) {
      _activeBatch = null;
      _activeIdempotencyKey = null;
    }
    return generateWithProgress();
  }

  /// 执行真实上传、完成上报和等待本地作品创建。
  Future<QuickGenerationBatch?> generateWithProgress() async {
    if (submitting.value) {
      return null;
    }
    submitting.value = true;
    _setProgress(
      const CreationGenerationProgress(
        phase: CreationGenerationPhase.creating,
        message: '创建上传任务...',
        progress: 0.02,
      ),
    );
    try {
      final selected = selectedMaterials;
      if (selected.isEmpty) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '请先选择视频',
        );
      }
      if (selected.any(
        (item) => item.filePath == null || item.filePath!.isEmpty,
      )) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '请重新选择本地视频后再生成',
        );
      }
      if (selected.any((item) => item.status == MaterialStatus.processing)) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '视频信息读取中，请稍后再生成',
        );
      }
      if (selected.any(
        (item) => item.durationSeconds <= 0 || item.fileSize <= 0,
      )) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '视频信息不完整，请重新选择视频',
        );
      }
      _requiredWorkTypeForGenerate(selected);

      var latest = await _createOrRefreshBatch();
      _throwIfFailed(latest);

      latest = await _uploadCover(latest, selected);
      _throwIfFailed(latest);

      for (var index = 0; index < selected.length; index++) {
        final material = selected[index];
        latest = await _ensureUploadCredentials(latest);
        _throwIfFailed(latest);
        final uploadItem = _uploadItemFor(latest, material.id);
        if (uploadItem.status != MaterialStatus.ready) {
          await _uploadMaterial(
            item: uploadItem,
            material: material,
            index: index,
            total: selected.length,
          );
        }
        _setProgress(
          CreationGenerationProgress(
            phase: CreationGenerationPhase.reporting,
            message: '上报第${index + 1}/${selected.length}个视频上传完成...',
            progress: _reportProgress(index, selected.length),
            current: index + 1,
            total: selected.length,
          ),
        );
        latest = await QuickGenerationAPI.completeUpload(
          batchId: latest.batchId,
          assetId: uploadItem.assetId,
        );
        _activeBatch = latest;
        _throwIfFailed(latest);
      }

      latest = await _waitUntilSubmitted(latest);
      _activeBatch = null;
      _activeIdempotencyKey = null;
      _setProgress(
        CreationGenerationProgress(
          phase: CreationGenerationPhase.succeeded,
          message: '作品已创建',
          progress: 1,
          current: selected.length,
          total: selected.length,
        ),
      );
      return latest;
    } catch (error) {
      _setProgress(
        CreationGenerationProgress(
          phase: CreationGenerationPhase.failed,
          message: '提交失败',
          progress: generationProgress.value.progress,
          current: generationProgress.value.current,
          total: generationProgress.value.total,
          errorMessage: _errorMessage(error),
        ),
      );
      return null;
    } finally {
      submitting.value = false;
    }
  }

  /// 打开视频相册并返回用户选择的视频文件。
  ///
  /// Android 避开 `image_picker` 的文件选择器 Intent，改用相册网格选择器；
  /// 其他平台保留系统多选能力。
  Future<List<XFile>> _pickVideosFromGallery(
    BuildContext context, {
    required int limit,
    required Duration maxDuration,
  }) async {
    if (Platform.isAndroid) {
      final assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: limit,
          requestType: RequestType.video,
          shouldAutoplayPreview: true,
          themeColor: const Color(0xFFCFFF36),
          textDelegate: const AssetPickerTextDelegate(),
        ),
      );
      if (assets == null || assets.isEmpty) {
        return const <XFile>[];
      }
      return _assetEntitiesToXFiles(assets);
    }
    return _picker.pickMultiVideo(maxDuration: maxDuration, limit: limit);
  }

  /// 将相册资源转换成后续上传链路可复用的本地文件。
  Future<List<XFile>> _assetEntitiesToXFiles(List<AssetEntity> assets) async {
    final files = <XFile>[];
    for (final asset in assets) {
      final file = await asset.file;
      if (file == null || file.path.trim().isEmpty) {
        continue;
      }
      files.add(XFile(file.path, name: asset.title));
    }
    return files;
  }

  /// 把系统选择器返回的视频加入页面列表。
  ///
  /// 这里会先插入读取中占位项，再异步读取时长、大小和缩略图。
  void _appendPickedVideos(List<XFile> pickedVideos, int remaining) {
    if (pickedVideos.isEmpty) {
      _showToast('未选择视频');
      return;
    }

    var added = 0;
    for (final picked in pickedVideos) {
      if (added >= remaining) {
        _showToast('最多添加10个视频');
        break;
      }
      final path = picked.path;
      if (path.trim().isEmpty) {
        _showToast('无法读取所选视频');
        continue;
      }
      final existing = _firstWhereOrNull<CreationMaterial>(
        materials,
        (item) => item.filePath == path,
      );
      if (existing != null) {
        if (existing.status == MaterialStatus.ready &&
            !_canAppendDuration(existing.durationSeconds)) {
          _showToast(_workTypeMismatchMessage(selectedWorkType.value));
          continue;
        }
        if (!store.selectedMaterialIds.contains(existing.id)) {
          store.selectedMaterialIds.add(existing.id);
          _syncLockedWorkTypeAfterSelectionChanged();
          added++;
        }
        continue;
      }

      final file = File(path);
      if (!file.existsSync()) {
        _showToast('视频文件不存在');
        continue;
      }

      final clientFileId = _newClientFileId();
      final material = CreationMaterial(
        id: clientFileId,
        name: picked.name,
        durationText: '读取中',
        durationSeconds: 0,
        thumbUrl: '',
        status: MaterialStatus.processing,
        filePath: path,
        fileSize: 0,
        contentType: lookupMimeType(path) ?? 'video/mp4',
      );
      materials.add(material);
      store.selectedMaterialIds.add(material.id);
      unawaited(_hydratePickedVideo(clientFileId, picked, file));
      added++;
    }
  }

  /// 异步补齐本地视频元信息。
  ///
  /// 选择阶段已经把占位项加入列表，这里只负责把占位项替换成可提交素材；
  /// 如果读取失败，直接移除占位项，避免用户看到无法提交又无法处理的坏数据。
  Future<void> _hydratePickedVideo(
    String clientFileId,
    XFile picked,
    File file,
  ) async {
    try {
      final duration = await _readVideoDuration(file);
      if (duration == null || duration.inSeconds <= 0) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '无法读取视频时长',
        );
      }
      if (!_hasMaterial(clientFileId)) {
        return;
      }
      if (duration > maxUploadVideoDuration) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '单个视频时长不能超过30分钟',
        );
      }
      final workType = _validateAndLockWorkType(duration.inSeconds);
      if (!workType.acceptsDuration(duration.inSeconds)) {
        throw const ApiException(
          type: ApiErrorType.validation,
          message: '视频时长不符合当前作品类型',
        );
      }

      final thumbnailPath = await VideoUtils.getFileThumbnail(file.path) ?? '';
      final size = await picked.length();
      _replaceMaterial(
        clientFileId,
        CreationMaterial(
          id: clientFileId,
          name: picked.name,
          durationText: _formatDurationText(duration.inSeconds),
          durationSeconds: duration.inSeconds,
          thumbUrl: thumbnailPath,
          status: MaterialStatus.ready,
          filePath: file.path,
          fileSize: size,
          contentType: lookupMimeType(file.path) ?? 'video/mp4',
        ),
      );
    } catch (error) {
      if (!_hasMaterial(clientFileId)) {
        return;
      }
      _removePickedVideo(clientFileId);
      _showToast(_errorMessage(error));
    }
  }

  /// 根据首个读取完成的视频锁定当前批次作品类型，并校验后续视频时长。
  ///
  /// 自动判定只在未锁定时发生；已经锁定后只根据该类型的百度项目规则判断
  /// 当前视频能否追加到同一个百度 project。
  WorkType _validateAndLockWorkType(int durationSeconds) {
    if (durationSeconds < 10) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: '单个视频时长不能少于10秒',
      );
    }

    final locked = selectedWorkType.value;
    if (locked != null) {
      if (!locked.acceptsDuration(durationSeconds)) {
        throw ApiException(
          type: ApiErrorType.validation,
          message: _workTypeMismatchMessage(locked),
        );
      }
      return locked;
    }

    final inferred = _inferWorkType(durationSeconds);
    selectedWorkType.value = inferred;
    return inferred;
  }

  /// 按产品确认的优先级从视频时长推导百度项目类型。
  ///
  /// 60 分钟及以上优先归为电影；20 分钟以内归为短剧；
  /// 中间段归为电视剧。
  WorkType _inferWorkType(int durationSeconds) {
    if (durationSeconds >= 60 * 60) {
      return WorkType.movie;
    }
    if (durationSeconds > 20 * 60) {
      return WorkType.tvSeries;
    }
    return WorkType.shortSeries;
  }

  /// 判断当前锁定类型是否允许追加指定时长的视频。
  bool _canAppendDuration(int durationSeconds) {
    final locked = selectedWorkType.value;
    return locked == null || locked.acceptsDuration(durationSeconds);
  }

  /// 生成当前作品类型下的视频时长不匹配提示。
  String _workTypeMismatchMessage(WorkType? workType) {
    if (workType == null) {
      return '视频时长不符合规则';
    }
    return '当前作品类型为${workType.label}，只能添加${workType.durationRuleText}视频';
  }

  /// 选择关系变化后同步锁定类型。
  ///
  /// 用户删除全部视频时清空类型；若测试或外部逻辑直接替换了选中列表，
  /// 则从剩余已读取视频中恢复一个稳定类型。
  void _syncLockedWorkTypeAfterSelectionChanged() {
    final ready = selectedMaterials
        .where((item) => item.status == MaterialStatus.ready)
        .toList(growable: false);
    if (ready.isEmpty) {
      selectedWorkType.value = null;
      return;
    }
    final locked = selectedWorkType.value;
    if (locked != null &&
        ready.every((item) => locked.acceptsDuration(item.durationSeconds))) {
      return;
    }
    selectedWorkType.value = _inferWorkType(ready.first.durationSeconds);
  }

  /// 提交前获取并复核当前批次作品类型。
  ///
  /// 正常 UI 流程下类型已在读取视频时锁定；这里额外兜底测试注入、
  /// 状态恢复或其他入口直接填充素材的情况。
  WorkType _requiredWorkTypeForGenerate(List<CreationMaterial> selected) {
    if (selected.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: '请先选择视频',
      );
    }
    final locked =
        selectedWorkType.value ??
        _inferWorkType(selected.first.durationSeconds);
    for (final item in selected) {
      if (!locked.acceptsDuration(item.durationSeconds)) {
        throw ApiException(
          type: ApiErrorType.validation,
          message: _workTypeMismatchMessage(locked),
        );
      }
    }
    selectedWorkType.value = locked;
    return locked;
  }

  /// 用读取完成的视频素材替换占位素材。
  void _replaceMaterial(String id, CreationMaterial next) {
    final index = materials.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    materials[index] = next;
  }

  /// 判断本地视频素材是否仍在页面列表中。
  bool _hasMaterial(String id) {
    return materials.any((item) => item.id == id);
  }

  /// 移除本地视频素材及其选中关系。
  void _removePickedVideo(String id) {
    store.selectedMaterialIds.remove(id);
    materials.removeWhere((item) => item.id == id);
    _syncLockedWorkTypeAfterSelectionChanged();
  }

  Future<bool> _loadConfigWithDialog(
    BuildContext context, {
    bool needStyles = false,
    bool needVoices = false,
  }) async {
    CustomToast.loading('加载配置...');
    try {
      await loadInitialData(force: true);
    } finally {
      CustomToast.dismiss();
    }
    if (!context.mounted) {
      return false;
    }
    if (needStyles && styles.isEmpty) {
      _showToast('暂无可用解说风格');
      return false;
    }
    if (needVoices && voices.isEmpty) {
      _showToast('暂无可用配音角色');
      return false;
    }
    return true;
  }

  Future<bool> _ensureRequiredConfigForGenerate(BuildContext context) async {
    if (styles.isNotEmpty && voices.isNotEmpty) {
      return true;
    }
    if (!await _loadConfigWithDialog(
      context,
      needStyles: true,
      needVoices: true,
    )) {
      return false;
    }
    if (store.selectedStyleId.value.isEmpty ||
        store.selectedVoiceRoleId.value.isEmpty) {
      _showToast('暂无可用创作配置');
      return false;
    }
    return true;
  }

  void _syncConfigFromService() {
    styles.assignAll(configService.styles);
    voices.assignAll(configService.voices);
  }

  /// 在配置加载完成后补齐默认风格和默认角色。
  void _ensureDefaultSelection() {
    if (styles.isNotEmpty &&
        !_containsId(styles, store.selectedStyleId.value)) {
      store.selectedStyleId.value = styles.first.id;
    }
    if (voices.isNotEmpty &&
        !_containsId(voices, store.selectedVoiceRoleId.value)) {
      store.selectedVoiceRoleId.value = voices.first.id;
    }
  }

  /// 判断给定 ID 是否存在于风格或角色列表中。
  bool _containsId<T>(Iterable<T> items, String id) {
    for (final item in items) {
      if (item is CreationStyle && item.id == id) {
        return true;
      }
      if (item is VoiceRole && item.id == id) {
        return true;
      }
    }
    return false;
  }

  /// 在迭代集合中查找第一个满足条件的元素。
  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  Iterable<String> _uniqueIds(Iterable<String> ids) sync* {
    final seen = <String>{};
    for (final id in ids) {
      final value = id.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      yield value;
    }
  }

  /// 格式化分钟数，用于选择视频摘要文案。
  String _formatMinutes(int seconds) {
    if (seconds <= 0) {
      return '0';
    }
    final minutes = seconds / 60;
    return minutes.toStringAsFixed(1);
  }

  /// 把当前本地素材转换为创建 quick batch 所需的文件清单。
  ///
  /// `clientFileId` 是前端临时 ID，后续用它把后端返回的 upload item
  /// 对应回本地文件。
  List<QuickGenerationFile> _quickFiles() {
    return selectedMaterials.map((item) {
      return QuickGenerationFile(
        clientFileId: item.id,
        fileName: item.name,
        fileSize: item.fileSize,
        contentType: item.contentType,
        type: item.type,
        durationSeconds: item.durationSeconds,
      );
    }).toList();
  }

  /// 创建或刷新快速生成批次。
  ///
  /// 同一个提交弹窗内复用 idempotency key，避免重试时后端重复创建
  /// 多个相同任务。
  Future<QuickGenerationBatch> _createOrRefreshBatch() async {
    _activeIdempotencyKey ??= _newIdempotencyKey();
    _setProgress(
      CreationGenerationProgress(
        phase: CreationGenerationPhase.creating,
        message: _activeBatch == null ? '创建上传任务...' : '刷新上传凭证...',
        progress: 0.05,
        current: generationProgress.value.current,
        total: selectedMaterials.length,
      ),
    );
    final batch = await QuickGenerationAPI.createBatch(
      title: selectedMaterials.first.name,
      files: _quickFiles(),
      style: store.selectedStyleId.value,
      voice: store.selectedVoiceRoleId.value,
      workType: _requiredWorkTypeForGenerate(selectedMaterials),
      presetId: store.selectedStyleId.value,
      diversifiedVersionsEnabled: store.diversifiedVersionsEnabled.value,
      idempotencyKey: _activeIdempotencyKey,
    );
    _activeBatch = batch;
    return batch;
  }

  /// 上传首个视频第一帧生成的封面。
  Future<QuickGenerationBatch> _uploadCover(
    QuickGenerationBatch batch,
    List<CreationMaterial> selected,
  ) async {
    final coverFile = await _coverFileFor(selected);
    if (coverFile == null) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: '封面生成失败，请重新选择视频',
      );
    }
    _setProgress(
      CreationGenerationProgress(
        phase: CreationGenerationPhase.uploading,
        message: '上传封面...',
        progress: 0.07,
        current: 0,
        total: selected.length,
      ),
    );
    final latest = await QuickGenerationAPI.uploadCover(
      batchId: batch.batchId,
      file: coverFile,
      onSendProgress: (sent, totalBytes) {
        final ratio = totalBytes <= 0 ? 0.0 : sent / totalBytes;
        _setProgress(
          CreationGenerationProgress(
            phase: CreationGenerationPhase.uploading,
            message: '上传封面...',
            progress: (0.07 + 0.05 * ratio.clamp(0.0, 1.0)).toDouble(),
            current: 0,
            total: selected.length,
          ),
        );
      },
    );
    _activeBatch = latest;
    return latest;
  }

  /// 找到或生成提交到后端的封面图片文件。
  Future<File?> _coverFileFor(List<CreationMaterial> selected) async {
    if (selected.isEmpty) {
      return null;
    }
    final thumbnailPath = selected.first.thumbUrl.trim();
    if (thumbnailPath.isNotEmpty) {
      final thumbnail = File(thumbnailPath);
      if (thumbnail.existsSync()) {
        return thumbnail;
      }
    }
    final videoPath = selected.first.filePath?.trim() ?? '';
    if (videoPath.isEmpty) {
      return null;
    }
    final generatedPath = await VideoUtils.getFileThumbnail(videoPath) ?? '';
    if (generatedPath.isEmpty) {
      return null;
    }
    final generated = File(generatedPath);
    return generated.existsSync() ? generated : null;
  }

  /// 后端返回的上传凭证为空时刷新批次详情。
  Future<QuickGenerationBatch> _ensureUploadCredentials(
    QuickGenerationBatch batch,
  ) async {
    final needsCredential = batch.uploadItems.any((item) {
      return item.status != MaterialStatus.ready && item.uploadUrl.isEmpty;
    });
    if (!needsCredential) {
      return batch;
    }
    return _createOrRefreshBatch();
  }

  /// 从批次详情中找到本地素材对应的上传项。
  QuickBatchUploadItem _uploadItemFor(QuickGenerationBatch batch, String id) {
    final item = _firstWhereOrNull<QuickBatchUploadItem>(
      batch.uploadItems,
      (candidate) => candidate.clientFileId == id,
    );
    if (item == null) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: '上传任务缺少视频信息',
      );
    }
    if (item.assetId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: '上传任务缺少媒资编号',
      );
    }
    return item;
  }

  /// 把单个本地视频直接 PUT 到后端返回的 Provider 上传地址。
  Future<void> _uploadMaterial({
    required QuickBatchUploadItem item,
    required CreationMaterial material,
    required int index,
    required int total,
  }) async {
    if (item.uploadUrl.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.serviceBusy,
        message: '上传地址为空，请稍后重试',
      );
    }
    final file = File(material.filePath!);
    if (!file.existsSync()) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: '视频文件不存在：${material.name}',
      );
    }
    _setProgress(
      CreationGenerationProgress(
        phase: CreationGenerationPhase.uploading,
        message: '上传第${index + 1}/$total个视频...',
        progress: _uploadProgress(index, total, 0),
        current: index + 1,
        total: total,
      ),
    );
    await QuickGenerationAPI.uploadFile(
      uploadUrl: item.uploadUrl,
      file: file,
      headers: item.uploadHeaders,
      onSendProgress: (sent, totalBytes) {
        final ratio = totalBytes <= 0 ? 0.0 : sent / totalBytes;
        _setProgress(
          CreationGenerationProgress(
            phase: CreationGenerationPhase.uploading,
            message: '上传第${index + 1}/$total个视频...',
            progress: _uploadProgress(
              index,
              total,
              ratio.clamp(0.0, 1.0).toDouble(),
            ),
            current: index + 1,
            total: total,
          ),
        );
      },
    );
  }

  /// 等待后端完成本地作品创建并返回 `workId`。
  Future<QuickGenerationBatch> _waitUntilSubmitted(
    QuickGenerationBatch latest,
  ) async {
    var current = latest;
    var pollCount = 0;
    while (true) {
      if (_isSubmitted(current)) {
        return current;
      }
      _throwIfFailed(current);
      pollCount++;
      _setProgress(
        CreationGenerationProgress(
          phase: CreationGenerationPhase.polling,
          message: current.status == QuickGenerationBatchStatus.analyzing
              ? '创建作品中...'
              : '加入项目中...',
          progress: (0.9 + pollCount * 0.004).clamp(0.9, 0.98).toDouble(),
          current: current.uploadedCount,
          total: current.totalCount,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      current = await QuickGenerationAPI.detail(current.batchId);
      _activeBatch = current;
    }
  }

  /// 判断批次是否已经创建本地作品，可以让前端关闭上传弹层。
  bool _isSubmitted(QuickGenerationBatch batch) {
    final hasWork = batch.workId != null && batch.workId!.trim().isNotEmpty;
    return hasWork &&
        (batch.status == QuickGenerationBatchStatus.analyzing ||
            batch.status == QuickGenerationBatchStatus.generating ||
            batch.status == QuickGenerationBatchStatus.succeeded);
  }

  /// 判断批次是否处于不可重用的终态失败。
  bool _isTerminalFailure(QuickGenerationBatchStatus status) {
    return status == QuickGenerationBatchStatus.failed ||
        status == QuickGenerationBatchStatus.canceled ||
        status == QuickGenerationBatchStatus.expired;
  }

  /// 把后端失败批次转换为前端异常。
  void _throwIfFailed(QuickGenerationBatch batch) {
    if (batch.status == QuickGenerationBatchStatus.failed) {
      throw ApiException(
        type: ApiErrorType.taskFailed,
        message: batch.failureMessage?.trim().isNotEmpty == true
            ? batch.failureMessage
            : '生成任务提交失败',
      );
    }
    if (batch.status == QuickGenerationBatchStatus.expired) {
      throw const ApiException(
        type: ApiErrorType.taskFailed,
        message: '上传任务已过期，请重新生成',
      );
    }
    if (batch.status == QuickGenerationBatchStatus.canceled) {
      throw const ApiException(
        type: ApiErrorType.taskFailed,
        message: '上传任务已取消',
      );
    }
  }

  /// 计算视频上传阶段的整体进度。
  double _uploadProgress(int index, int total, double ratio) {
    if (total <= 0) {
      return 0.12;
    }
    const uploadStart = 0.12;
    const uploadWeight = 0.68;
    return uploadStart + uploadWeight * ((index + ratio) / total);
  }

  /// 计算上传完成上报阶段的整体进度。
  double _reportProgress(int index, int total) {
    if (total <= 0) {
      return 0.82;
    }
    return (0.8 + 0.1 * ((index + 1) / total)).clamp(0.8, 0.9).toDouble();
  }

  /// 更新上传/提交弹层的进度快照。
  void _setProgress(CreationGenerationProgress progress) {
    generationProgress.value = progress;
  }

  /// 处理系统视频选择器返回的异常。
  void _handleVideoPickerException(
    BuildContext context,
    PlatformException error,
  ) {
    final code = error.code.toLowerCase();
    if (Platform.isIOS &&
        (code == 'photo_access_denied' || code == 'photo_access_restricted')) {
      Access.showPhotosDialog(context, '请在系统设置中允许访问照片中的视频，然后返回重新选择。');
      return;
    }

    if (code == 'multiple_request') {
      _showToast('视频选择器已打开，请稍后再试');
      return;
    }

    final message = error.message?.trim();
    _showToast(message?.isNotEmpty == true ? message! : '无法打开视频选择器');
  }

  /// 读取本地视频文件时长。
  Future<Duration?> _readVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  /// 把秒数格式化为 `HH:mm:ss`。
  String _formatDurationText(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final secs = safeSeconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}:${two(secs)}';
  }

  /// 生成本地视频素材的临时 ID。
  String _newClientFileId() {
    return 'local_${DateTime.now().microsecondsSinceEpoch}_${materials.length}';
  }

  /// 生成 quick batch 提交幂等键。
  String _newIdempotencyKey() {
    return 'quick_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// 把异常转换为用户可读错误文案。
  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.userMessage;
    }
    if (error is DioException) {
      final message = error.response?.data is Map
          ? '${(error.response!.data as Map)['message'] ?? ''}'
          : '';
      if (message.trim().isNotEmpty) {
        return message;
      }
      return error.message ?? '上传失败，请稍后重试';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  /// 展示创作流程中的短提示。
  void _showToast(String message) {
    CustomToast.text(message);
  }
}
