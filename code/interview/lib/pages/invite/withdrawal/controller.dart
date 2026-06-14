part of 'index.dart';

/// 提现子流程的业务与状态控制类。
///
/// 页面进入时加载提现所需的概览与收益汇总；提交时校验金额、账户和协议确认，
/// mock/real 分支都由 Controller 内部处理。
final class InviteWithdrawalController extends GetxController {
  /// 邀请概览数据，提供最低提现金额等规则兜底。
  final Rxn<InviteOverview> overview = Rxn<InviteOverview>();

  /// 收益汇总数据，提供当前可提现金额。
  final Rxn<InviteEarningSummary> earningSummary = Rxn<InviteEarningSummary>();

  /// 页面加载状态；驱动提现页 loading / retry。
  final RxBool loading = false.obs;

  /// 提现申请提交状态，用于禁用按钮避免重复点击。
  final RxBool withdrawing = false.obs;

  /// 用户是否已确认提现规则和合作协议。
  final RxBool withdrawalAgreementAccepted = false.obs;

  /// 当前提现账号展示值；账号弹层确认后同步。
  final RxString withdrawAccountDisplay = ''.obs;

  /// 页面加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  /// 提现金额输入框控制器。
  final TextEditingController withdrawAmountController =
      TextEditingController();

  /// 支付宝账号输入框控制器。
  final TextEditingController withdrawAccountController =
      TextEditingController();

  /// 收款人姓名输入框控制器。
  final TextEditingController withdrawNameController = TextEditingController();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadWithdrawal();
  }

  @override
  void onClose() {
    withdrawAmountController.dispose();
    withdrawAccountController.dispose();
    withdrawNameController.dispose();
    super.onClose();
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

  /// 当前可提现金额，单位为分。
  int get withdrawableCents {
    return earningSummary.value?.withdrawableCents ??
        overview.value?.withdrawableCents ??
        0;
  }

  /// 加载提现页所需的规则与余额数据。
  Future<void> loadWithdrawal() async {
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

  /// 将全部可提现余额填入金额输入框。
  void fillAllWithdrawable() {
    withdrawAmountController.text = inviteFormatYuan(withdrawableCents);
  }

  /// 切换提现规则确认状态。
  void toggleAgreementAccepted() {
    withdrawalAgreementAccepted.value = !withdrawalAgreementAccepted.value;
  }

  /// 同步提现账号展示文案。
  void syncWithdrawAccountDisplay() {
    withdrawAccountDisplay.value = withdrawAccountController.text.trim();
  }

  /// 创建提现申请。
  ///
  /// 校验失败只弹 toast 并保留表单；成功后清空金额、账号、姓名和协议勾选，
  /// 并重新加载余额数据以同步可提现金额。
  Future<void> createWithdrawal() async {
    final amountCents = _amountCents(withdrawAmountController.text);
    if (amountCents <= 0) {
      CustomToast.text('请输入正确的提现金额');
      return;
    }
    final minWithdraw = overview.value?.minWithdrawCents ?? 100;
    if (amountCents < minWithdraw) {
      CustomToast.text('最低提现金额为 ${inviteFormatMoney(minWithdraw)}');
      return;
    }
    final summary = earningSummary.value;
    if (summary != null && amountCents > summary.withdrawableCents) {
      CustomToast.text('可提现余额不足');
      return;
    }
    final accountNo = withdrawAccountController.text.trim();
    final accountName = withdrawNameController.text.trim();
    if (accountNo.isEmpty || accountName.isEmpty) {
      CustomToast.text('请填写提现账号和收款人姓名');
      return;
    }
    if (!withdrawalAgreementAccepted.value) {
      CustomToast.text('请先确认提现规则');
      return;
    }

    withdrawing.value = true;
    try {
      if (_useMock) {
        await _mock.resolve<InviteWithdrawal>(
          InviteWithdrawal(
            id: 'withdraw_${DateTime.now().millisecondsSinceEpoch}',
            amountCents: amountCents,
            channel: 'ALIPAY',
            accountNoMasked: _maskAccount(accountNo),
            accountName: accountName,
            status: 'PENDING_REVIEW',
            reviewRemark: '',
            createdAtText: '刚刚',
          ),
          mockKey: 'invite.withdrawals.create',
        );
      } else {
        await InviteAPI.createWithdrawal(
          amountCents: amountCents,
          channel: 'ALIPAY',
          accountNo: accountNo,
          accountName: accountName,
          agreementAccepted: true,
        );
      }
      withdrawAmountController.clear();
      withdrawAccountController.clear();
      withdrawNameController.clear();
      withdrawalAgreementAccepted.value = false;
      syncWithdrawAccountDisplay();
      CustomToast.success('提现申请已提交');
      await loadWithdrawal();
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
    } finally {
      withdrawing.value = false;
    }
  }

  /// 获取邀请概览，mock 模式下使用提现页私有样例数据。
  Future<InviteOverview> _overview() {
    if (!_useMock) {
      return InviteAPI.overview();
    }
    return _mock.resolve<InviteOverview>(
      _mockOverview,
      mockKey: 'invite.overview',
    );
  }

  /// 获取收益汇总，mock 模式下使用提现页私有样例数据。
  Future<InviteEarningSummary> _earningSummary() {
    if (!_useMock) {
      return InviteAPI.earningSummary();
    }
    return _mock.resolve<InviteEarningSummary>(
      _mockSummary,
      mockKey: 'invite.earnings.summary',
    );
  }

  int _amountCents(String value) {
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 0;
    }
    return (amount * 100).round();
  }

  String _maskAccount(String accountNo) {
    if (accountNo.length <= 4) {
      return '****';
    }
    return '****${accountNo.substring(accountNo.length - 4)}';
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
