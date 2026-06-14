part of 'index.dart';

final class WorksController extends GetxController {
  WorksController({Duration? pollingInterval})
    : pollingInterval = pollingInterval ?? defaultPollingInterval;

  /// 作品页轮询默认间隔。
  ///
  /// 业务要求大约 3 分钟查询一次；抽成变量方便测试和后续调整。
  static const Duration defaultPollingInterval = Duration(minutes: 3);

  /// 当前 Controller 实例使用的轮询间隔。
  final Duration pollingInterval;

  final UserStore userStore = Get.find<UserStore>();

  final RxBool loading = false.obs;
  final RxBool hidingWorks = false.obs;
  final RxBool isManaging = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString batchActionErrorMessage = RxnString();
  final Rx<WorkType> selectedCategory = WorkType.all.obs;
  final RxList<Work> works = <Work>[].obs;
  final RxList<WorkType> _availableWorkTypes = <WorkType>[].obs;

  /// 批量管理模式下选中的作品 id。
  ///
  /// 删除入口实际会调用隐藏接口，保留 id 列表可以避免给 [Work] 模型塞 UI 状态。
  final RxList<String> selectedWorkIds = <String>[].obs;

  /// 登录态变化监听；登录/退出后按当前作品页可见状态重新判断轮询。
  Worker? _authWorker;

  /// 作品创建成功后的列表刷新事件订阅。
  ///
  /// 创作流程只负责发出 [WorksListRefreshRequested]，作品页自己决定如何刷新。
  StreamSubscription<WorksListRefreshRequested>? _refreshSubscription;

  /// 作品页可见性变化事件订阅，用于启动或停止轮询。
  StreamSubscription<WorksPageVisibilityChanged>? _visibilitySubscription;

  /// 作品页是否处于用户当前可见的底部 Tab。
  bool _worksPageActive = false;

  /// 作品列表轮询定时器；同一时刻最多存在一个。
  Timer? _pollingTimer;

  final List<WorkType> categories = const <WorkType>[
    WorkType.all,
    WorkType.shortSeries,
    WorkType.movie,
    WorkType.tvSeries,
  ];

  /// 当前应展示的作品类型标签。
  ///
  /// “全部”始终展示；短剧/电影/电视剧来自全部作品的类型快照，而不是当前筛选
  /// 结果。否则用户点击“短剧”后，电影作品会因为当前列表被筛掉而误隐藏。
  List<WorkType> get visibleCategories {
    final availableTypes = _availableWorkTypes.toSet();
    return categories
        .where((type) => type == WorkType.all || availableTypes.contains(type))
        .toList(growable: false);
  }

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    if (works.isEmpty) {
      return ViewState.empty;
    }
    return ViewState.success;
  }

  int get selectedCount => selectedWorkIds.length;

  List<Work> get selectableWorks {
    return works.where(isWorkSelectable).toList(growable: false);
  }

  bool get allSelectableSelected {
    final selectable = selectableWorks;
    return selectable.isNotEmpty &&
        selectable.every((work) => selectedWorkIds.contains(work.id));
  }

  @override
  void onInit() {
    super.onInit();
    _authWorker = ever<String?>(userStore.token, _handleAuthChanged);
    _listenForRefreshRequests();
    loadWorks();
  }

  @override
  void onClose() {
    _stopPolling();
    _authWorker?.dispose();
    unawaited(_refreshSubscription?.cancel());
    unawaited(_visibilitySubscription?.cancel());
    super.onClose();
  }

  /// 监听跨页面的作品列表刷新请求。
  void _listenForRefreshRequests() {
    if (!Get.isRegistered<EventService>()) {
      return;
    }
    final eventService = Get.find<EventService>();
    _refreshSubscription = eventService.on<WorksListRefreshRequested>().listen(
      _handleWorksListRefreshRequested,
    );
    _visibilitySubscription = eventService
        .on<WorksPageVisibilityChanged>()
        .listen(_handleWorksPageVisibilityChanged);
  }

  /// 收到作品创建成功事件后刷新列表。
  void _handleWorksListRefreshRequested(WorksListRefreshRequested event) {
    unawaited(loadWorks());
  }

  /// 登录态变化时，根据当前作品页是否可见重新决定轮询生命周期。
  void _handleAuthChanged(String? token) {
    if (!userStore.isLoggedIn) {
      _stopPolling();
      unawaited(loadWorks());
      return;
    }
    if (_worksPageActive) {
      _startPolling(refreshImmediately: true);
      return;
    }
    unawaited(loadWorks());
  }

  /// 作品页进入/离开当前可见 Tab 时启动或停止轮询。
  void _handleWorksPageVisibilityChanged(WorksPageVisibilityChanged event) {
    if (_worksPageActive == event.active) {
      return;
    }
    _worksPageActive = event.active;
    if (!_worksPageActive) {
      _stopPolling();
      return;
    }
    _startPolling(refreshImmediately: true);
  }

  /// 启动作品列表轮询；如果已有活跃定时器则复用，避免重复轮询。
  void _startPolling({required bool refreshImmediately}) {
    if (!userStore.isLoggedIn) {
      _stopPolling();
      return;
    }
    if (_pollingTimer == null || !_pollingTimer!.isActive) {
      _pollingTimer = Timer.periodic(pollingInterval, (_) => _pollWorks());
    }
    if (refreshImmediately) {
      unawaited(loadWorks());
    }
  }

  /// 停止作品列表轮询并释放定时器。
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 轮询触发的刷新入口。
  ///
  /// 如果一次刷新还没结束，跳过本轮，避免慢接口场景下请求堆叠。
  void _pollWorks() {
    if (loading.value) {
      return;
    }
    unawaited(loadWorks());
  }

  Future<void> loadWorks() async {
    if (!userStore.isLoggedIn) {
      loading.value = false;
      errorMessage.value = null;
      works.clear();
      _availableWorkTypes.clear();
      _resetBatchMode();
      return;
    }

    loading.value = true;
    errorMessage.value = null;
    try {
      final category = selectedCategory.value;
      final result = await _fetchWorks(category: category);
      works.assignAll(result.items);
      if (category == WorkType.all) {
        _syncAvailableWorkTypes(result.items);
      } else {
        await _refreshAvailableWorkTypes();
      }
      _retainExistingSelections();
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshWorks() async {
    await loadWorks();
  }

  void selectCategory(WorkType category) {
    if (selectedCategory.value == category) {
      return;
    }
    selectedCategory.value = category;
    _resetBatchMode();
    loadWorks();
  }

  void showMoreActions(Work work) {
    CustomToast.text('${work.title} 更多操作待后端策略确认');
  }

  void toggleManageMode() {
    if (isManaging.value) {
      exitManageMode();
      return;
    }
    enterManageMode();
  }

  void enterManageMode() {
    if (!userStore.isLoggedIn) {
      CustomToast.text('请先登录');
      return;
    }
    if (works.isEmpty) {
      CustomToast.text('暂无作品可管理');
      return;
    }
    isManaging.value = true;
    selectedWorkIds.clear();
    batchActionErrorMessage.value = null;
  }

  void exitManageMode() {
    _resetBatchMode();
  }

  bool isWorkSelected(Work work) => selectedWorkIds.contains(work.id);

  bool isWorkSelectable(Work work) {
    return work.status != WorkStatus.generating &&
        work.status != WorkStatus.queued;
  }

  void toggleWorkSelection(Work work) {
    if (!isManaging.value) {
      return;
    }
    if (!isWorkSelectable(work)) {
      CustomToast.text('作品生成中，请稍后操作');
      return;
    }
    if (selectedWorkIds.contains(work.id)) {
      selectedWorkIds.remove(work.id);
      return;
    }
    selectedWorkIds.add(work.id);
  }

  void toggleSelectAllWorks() {
    final selectableIds = selectableWorks.map((work) => work.id).toList();
    if (selectableIds.isEmpty) {
      CustomToast.text('暂无可操作作品');
      return;
    }
    if (allSelectableSelected) {
      selectedWorkIds.clear();
      return;
    }
    selectedWorkIds.assignAll(selectableIds);
  }

  /// 执行批量“删除”。
  ///
  /// 这里遵循后端策略调用隐藏接口，只让作品从“我的作品”列表消失，不做物理删除。
  Future<bool> hideSelectedWorks() async {
    if (!userStore.isLoggedIn) {
      _resetBatchMode();
      return false;
    }
    final ids = selectedWorkIds.toList(growable: false);
    if (ids.isEmpty) {
      return false;
    }

    hidingWorks.value = true;
    batchActionErrorMessage.value = null;
    try {
      await _hideWorks(ids);
      final hiddenIds = ids.toSet();
      works.removeWhere((work) => hiddenIds.contains(work.id));
      await _refreshAvailableWorkTypes();
      _resetBatchMode();
      CustomToast.text('删除成功');
      return true;
    } on ApiException catch (error) {
      batchActionErrorMessage.value = error.userMessage;
      CustomToast.text(error.userMessage);
      return false;
    } finally {
      hidingWorks.value = false;
    }
  }

  Future<PageResult<Work>> _fetchWorks({required WorkType category}) async {
    if (!_useMock) {
      return WorksAPI.fetchWorks(workType: category);
    }
    final source = category == WorkType.all
        ? _mockWorks
        : _mockWorks.where((item) => item.workType == category).toList();
    final items = await _mock.resolveList<Work>(source, mockKey: 'works.list');
    return PageResult<Work>(items: items, total: items.length, hasMore: false);
  }

  /// 刷新全部作品类型快照。
  ///
  /// 分类标签依赖全部作品中存在的类型，而当前列表可能已经被某个类型筛选过。
  /// 这里单独取一页全部作品用于计算标签，失败时保留旧快照，不影响主列表展示。
  Future<void> _refreshAvailableWorkTypes() async {
    try {
      final result = await _fetchWorks(category: WorkType.all);
      _syncAvailableWorkTypes(result.items);
    } catch (_) {
      // 类型快照失败不阻断作品列表，下一次刷新会继续尝试。
    }
  }

  /// 从全部作品列表中同步当前有数据的作品类型。
  void _syncAvailableWorkTypes(List<Work> source) {
    final types = source
        .map((work) => work.workType)
        .where((type) => type != WorkType.all)
        .toSet()
        .toList(growable: false);
    types.sort(
      (left, right) =>
          categories.indexOf(left).compareTo(categories.indexOf(right)),
    );
    _availableWorkTypes.assignAll(types);
  }

  Future<void> _hideWorks(List<String> ids) async {
    if (!_useMock) {
      await WorksAPI.hideWorks(ids);
      return;
    }
    await _mock.resolve<bool>(true, mockKey: 'works.hide');
  }

  void _resetBatchMode() {
    isManaging.value = false;
    selectedWorkIds.clear();
    batchActionErrorMessage.value = null;
  }

  void _retainExistingSelections() {
    if (selectedWorkIds.isEmpty) {
      return;
    }
    final availableIds = works.map((work) => work.id).toSet();
    selectedWorkIds.removeWhere((id) => !availableIds.contains(id));
    if (works.isEmpty) {
      _resetBatchMode();
    }
  }

  static const List<Work> _mockWorks = <Work>[
    Work(
      id: 'work_001',
      title: '夜晚的城市街道',
      coverUrl: '',
      durationText: '01:26',
      status: WorkStatus.succeeded,
      workType: WorkType.shortSeries,
      createdAtText: '今天 12:20',
    ),
    Work(
      id: 'work_002',
      title: '电影剧情顺剪',
      coverUrl: '',
      durationText: '00:58',
      status: WorkStatus.generating,
      workType: WorkType.movie,
      createdAtText: '今天 10:18',
    ),
    Work(
      id: 'work_003',
      title: '切片快剪-小说转漫画-悬疑惊悚19701',
      coverUrl: '',
      durationText: '03:20',
      status: WorkStatus.draft,
      workType: WorkType.movie,
      createdAtText: '2026-01-26',
    ),
    Work(
      id: 'work_004',
      title: '电视剧高能片段解说',
      coverUrl: '',
      durationText: '02:12',
      status: WorkStatus.failed,
      workType: WorkType.tvSeries,
      createdAtText: '2026-01-25',
    ),
  ];
}
