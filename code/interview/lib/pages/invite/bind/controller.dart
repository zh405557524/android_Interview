part of 'index.dart';

/// 绑定邀请人子流程的业务控制类。
///
/// 该页面不预加载邀请概览，只在用户提交邀请码时调用绑定接口；成功后清空输入
/// 并提示用户，失败时保留当前输入，方便用户修正。
final class InviteBindController extends GetxController {
  /// 邀请码输入框控制器；提交失败时保留内容。
  final TextEditingController bindCodeController = TextEditingController();

  /// 绑定接口提交状态，用于禁用按钮避免重复点击。
  final RxBool binding = false.obs;

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onClose() {
    bindCodeController.dispose();
    super.onClose();
  }

  /// 提交邀请码绑定邀请人。
  ///
  /// mock 模式只模拟成功返回；真实模式调用 [InviteAPI.bind]。成功后清空表单，
  /// 失败时展示 toast 并保留用户已输入的邀请码。
  Future<void> bindInviteCode() async {
    final inviteCode = bindCodeController.text.trim();
    if (inviteCode.isEmpty) {
      CustomToast.text('请输入邀请人的邀请码');
      return;
    }
    binding.value = true;
    try {
      if (_useMock) {
        await _mock.resolve<InviteOverview>(
          _mockOverview,
          mockKey: 'invite.bind',
        );
      } else {
        await InviteAPI.bind(inviteCode);
      }
      bindCodeController.clear();
      CustomToast.success('邀请人绑定成功');
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
    } finally {
      binding.value = false;
    }
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
