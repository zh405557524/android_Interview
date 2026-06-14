part of 'index.dart';

/// 会员佣金规则子流程的业务与状态控制类。
///
/// 页面进入时加载邀请概览，用其中的代理等级和佣金比例渲染规则说明。
final class InviteRulesController extends GetxController {
  /// 邀请概览数据，提供佣金比例和规则说明。
  final Rxn<InviteOverview> overview = Rxn<InviteOverview>();

  /// 页面加载状态；驱动规则页 loading / retry。
  final RxBool loading = false.obs;

  /// 页面加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadRules();
  }

  /// 当前页面整体展示状态。
  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    return ViewState.success;
  }

  /// 加载会员佣金规则展示所需的概览数据。
  Future<void> loadRules() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      overview.value = await _overview();
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 获取邀请概览，mock 模式下使用规则页私有样例数据。
  Future<InviteOverview> _overview() {
    if (!_useMock) {
      return InviteAPI.overview();
    }
    return _mock.resolve<InviteOverview>(
      _mockOverview,
      mockKey: 'invite.overview',
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
}
