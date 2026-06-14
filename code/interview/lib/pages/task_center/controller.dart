part of 'index.dart';

/// 任务中心页面状态控制器，负责概览加载、签到领取和推广素材页跳转。
final class TaskCenterController extends GetxController {
  /// 全局用户状态，用于在任务中心刷新或签到成功后同步积分余额。
  final UserStore userStore = Get.find<UserStore>();

  /// 首次进入或手动重试时的页面加载状态。
  final RxBool loading = false.obs;

  /// 签到按钮提交中的状态，用于防止重复点击。
  final RxBool signing = false.obs;

  /// 概览加载失败时展示给用户的错误文案。
  final RxnString errorMessage = RxnString();

  /// 后端返回的任务中心概览数据，驱动页面全部卡片展示。
  final Rxn<TaskCenterOverview> overview = Rxn<TaskCenterOverview>();

  /// 是否使用本地 mock 数据，便于无后端环境下预览任务中心。
  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;

  /// 工程统一 mock 服务，用于构造任务中心接口兜底数据。
  MockService get _mock => Get.find<MockService>();

  /// 将加载 / 错误 / 成功状态转换为通用页面状态组件需要的枚举。
  ViewState get pageState {
    if (loading.value && overview.value == null) {
      return ViewState.loading;
    }
    if (errorMessage.value != null && overview.value == null) {
      return ViewState.error;
    }
    return ViewState.success;
  }

  /// 页面初始化时自动加载任务中心概览。
  @override
  void onInit() {
    super.onInit();
    loadOverview();
  }

  /// 加载当前用户任务中心概览。
  ///
  /// [silent] 为 true 时用于下拉刷新，失败只提示 Toast，不切换整页错误态。
  Future<void> loadOverview({bool silent = false}) async {
    if (!silent) {
      loading.value = true;
    }
    errorMessage.value = null;
    try {
      final result = _useMock ? await _mockOverview() : await TasksAPI.center();
      overview.value = result;
      userStore.points.value = result.totalPoints;
    } on ApiException catch (error) {
      if (silent) {
        CustomToast.text(error.userMessage);
      } else {
        errorMessage.value = error.userMessage;
      }
    } finally {
      if (!silent) {
        loading.value = false;
      }
    }
  }

  /// 执行今日签到，成功后更新页面签到状态和全局用户积分余额。
  Future<void> checkIn() async {
    final current = overview.value;
    if (signing.value || current == null || current.checkIn.signedToday) {
      return;
    }

    signing.value = true;
    try {
      final result = _useMock
          ? await _mockCheckIn(current)
          : await TasksAPI.checkIn();
      overview.value = TaskCenterOverview(
        enabled: current.enabled,
        totalPoints: result.totalPoints,
        checkIn: TaskCheckInOverview(
          signedToday: result.signedToday,
          consecutiveDays: result.consecutiveDays,
          cycleDay: result.cycleDay,
          todayRewardPoints: result.rewardPoints,
          days: result.days,
        ),
        dailyTasks: current.dailyTasks,
      );
      userStore.points.value = result.totalPoints;
      CustomToast.success(
        result.firstTime ? '签到成功，+${result.rewardPoints} 积分' : '今日已签到',
      );
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        error.userMessage,
        error: error,
        stackTrace: stackTrace,
        tag: '[TaskCenter]',
      );
    } finally {
      signing.value = false;
    }
  }

  /// 跳转到推广素材页面，让邀请任务直接进入可分享素材。
  void openInvite(BuildContext context) {
    context.pushNamed(RouteName.inviteMaterials);
  }

  /// 构造任务中心概览 mock 数据，保持与第一版后端返回结构一致。
  Future<TaskCenterOverview> _mockOverview() {
    final rewards = const [3, 3, 4, 3, 4, 5, 10];
    return _mock.resolve<TaskCenterOverview>(
      TaskCenterOverview(
        enabled: true,
        totalPoints: userStore.points.value == 0 ? 120 : userStore.points.value,
        checkIn: TaskCheckInOverview(
          signedToday: false,
          consecutiveDays: 2,
          cycleDay: 3,
          todayRewardPoints: rewards[2],
          days: [
            for (var index = 0; index < rewards.length; index += 1)
              TaskCheckInDay(
                day: index + 1,
                rewardPoints: rewards[index],
                checked: index < 2,
                current: index == 2,
              ),
          ],
        ),
        dailyTasks: const [
          TaskCenterItem(
            code: 'INVITE_FRIEND',
            title: '邀请好友领积分',
            description: '邀请好友注册，复用邀请奖励',
            target: 1,
            progress: 0,
            rewardText: '+10/人',
            actionText: '去邀请',
            routeName: 'inviteMaterials',
            completed: false,
            enabled: true,
          ),
        ],
      ),
      mockKey: 'tasks.center',
    );
  }

  /// 构造签到成功 mock 结果，用于本地验证签到后积分与节点状态刷新。
  Future<TaskCheckInResult> _mockCheckIn(TaskCenterOverview current) {
    final reward = current.checkIn.todayRewardPoints;
    final latestPoints = current.totalPoints + reward;
    final days = current.checkIn.days.map((day) {
      return TaskCheckInDay(
        day: day.day,
        rewardPoints: day.rewardPoints,
        checked: day.checked || day.current,
        current: day.current,
      );
    }).toList();
    return _mock.resolve<TaskCheckInResult>(
      TaskCheckInResult(
        signedToday: true,
        firstTime: true,
        rewardPoints: reward,
        totalPoints: latestPoints,
        consecutiveDays: current.checkIn.consecutiveDays + 1,
        cycleDay: current.checkIn.cycleDay,
        days: days,
      ),
      mockKey: 'tasks.check-in',
    );
  }
}
