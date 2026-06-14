part of 'index.dart';

/// 提现记录子流程的业务与状态控制类。
///
/// 页面进入时加载收益汇总和提现记录列表，汇总用于顶部累计收益卡片。
final class InviteWithdrawalRecordsController extends GetxController {
  /// 收益汇总数据，提供顶部累计收益金额。
  final Rxn<InviteEarningSummary> earningSummary = Rxn<InviteEarningSummary>();

  /// 提现记录列表数据源。
  final RxList<InviteWithdrawal> withdrawals = <InviteWithdrawal>[].obs;

  /// 页面加载状态；驱动提现记录 loading / retry。
  final RxBool loading = false.obs;

  /// 页面加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadWithdrawals();
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

  /// 加载收益汇总和提现记录。
  Future<void> loadWithdrawals() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await Future.wait<Object>([
        _earningSummary(),
        _withdrawals(),
      ]);
      earningSummary.value = result[0] as InviteEarningSummary;
      withdrawals.assignAll((result[1] as PageResult<InviteWithdrawal>).items);
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 获取收益汇总，mock 模式下使用记录页私有样例数据。
  Future<InviteEarningSummary> _earningSummary() {
    if (!_useMock) {
      return InviteAPI.earningSummary();
    }
    return _mock.resolve<InviteEarningSummary>(
      _mockSummary,
      mockKey: 'invite.earnings.summary',
    );
  }

  /// 获取提现记录，mock 模式下使用记录页私有样例数据。
  Future<PageResult<InviteWithdrawal>> _withdrawals() async {
    if (!_useMock) {
      return InviteAPI.withdrawals();
    }
    final items = await _mock.resolveList<InviteWithdrawal>(
      _mockWithdrawals,
      mockKey: 'invite.withdrawals',
    );
    return PageResult<InviteWithdrawal>(
      items: items,
      total: items.length,
      hasMore: false,
    );
  }

  static const InviteEarningSummary _mockSummary = InviteEarningSummary(
    todayEarningsCents: 0,
    yesterdayEarningsCents: 0,
    totalEarningsCents: 186000,
    withdrawableCents: 2120,
    withdrawingCents: 1000,
    paidCents: 0,
  );

  static const List<InviteWithdrawal> _mockWithdrawals = <InviteWithdrawal>[
    InviteWithdrawal(
      id: 'withdraw_001',
      amountCents: 383600,
      channel: 'ALIPAY',
      accountNoMasked: '****2026',
      accountName: '张三',
      status: 'PAID',
      reviewRemark: '',
      createdAtText: '2025.05.29 14:41',
    ),
    InviteWithdrawal(
      id: 'withdraw_002',
      amountCents: 383600,
      channel: 'ALIPAY',
      accountNoMasked: '****2026',
      accountName: '张三',
      status: 'PAY_FAILED',
      reviewRemark: '',
      createdAtText: '2025.05.29 14:41',
    ),
    InviteWithdrawal(
      id: 'withdraw_003',
      amountCents: 383600,
      channel: 'ALIPAY',
      accountNoMasked: '****2026',
      accountName: '张三',
      status: 'APPROVED',
      reviewRemark: '',
      createdAtText: '2025.05.29 14:41',
    ),
  ];
}
