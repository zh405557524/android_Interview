part of 'index.dart';

/// 邀请收益入口页的业务与状态控制类。
///
/// 入口页只加载收益概览与收益汇总，记录、提现、素材等子流程进入独立路由后
/// 再分别请求自己的数据，避免打开邀请入口时一次性发起过多请求。
final class InviteController extends GetxController {
  /// 当前用户状态仓库，用于展示头像旁手机号和邀请码兜底。
  final UserStore userStore = Get.find<UserStore>();

  /// 入口页加载状态；驱动收益首页 loading / retry。
  final RxBool loading = false.obs;

  /// 入口页加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  /// 邀请概览数据，包含代理等级、团队人数和提现规则等摘要。
  final Rxn<InviteOverview> overview = Rxn<InviteOverview>();

  /// 收益汇总数据，包含今日、昨日、累计和可提现金额。
  final Rxn<InviteEarningSummary> earningSummary = Rxn<InviteEarningSummary>();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadInvite();
  }

  /// 入口页整体展示状态。
  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    return ViewState.success;
  }

  /// 当前页面展示的用户邀请码，接口为空时使用用户仓库兜底。
  String get inviteCode =>
      overview.value?.inviteCode ?? userStore.inviteCode.value;

  /// 刷新邀请入口页需要的轻量收益数据。
  Future<void> loadInvite() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await Future.wait<Object>([
        _overview(),
        _earningSummary(),
      ]);
      overview.value = result[0] as InviteOverview;
      earningSummary.value = result[1] as InviteEarningSummary;
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 获取邀请概览，mock 模式下使用入口页私有样例数据。
  Future<InviteOverview> _overview() {
    if (!_useMock) {
      return InviteAPI.overview();
    }
    return _mock.resolve<InviteOverview>(
      _mockOverview,
      mockKey: 'invite.overview',
    );
  }

  /// 获取收益汇总，mock 模式下使用入口页私有样例数据。
  Future<InviteEarningSummary> _earningSummary() {
    if (!_useMock) {
      return InviteAPI.earningSummary();
    }
    return _mock.resolve<InviteEarningSummary>(
      _mockSummary,
      mockKey: 'invite.earnings.summary',
    );
  }

  static const InviteOverview _mockOverview = InviteOverview(
    inviteCode: 'JS2026',
    inviteLink:
        'https://api.lxwanxiang.com/invite/register.html?inviteCode=JS2026',
    ruleText: '注册奖励 10 积分；直接收益按个人代理等级 10% / 20% / 30%；间接收益由后台开启，固定 10%，仅一层。',
    totalRewards: 30,
    invitedCount: 35,
    rewardedCount: 3,
    memberCount: 21,
    agentLevel: 2,
    directInviteCount: 12,
    directCommissionRate: 20,
    indirectCommissionEnabled: true,
    indirectCommissionRate: 10,
    totalEarningsCents: 186000,
    withdrawableCents: 2120,
    minWithdrawCents: 100,
  );

  static const InviteEarningSummary _mockSummary = InviteEarningSummary(
    todayEarningsCents: 0,
    yesterdayEarningsCents: 0,
    totalEarningsCents: 186000,
    withdrawableCents: 2120,
    withdrawingCents: 1000,
    paidCents: 0,
  );
}
