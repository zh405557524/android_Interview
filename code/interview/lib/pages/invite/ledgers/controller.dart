part of 'index.dart';

/// 收益明细子流程的业务与状态控制类。
///
/// 页面进入时只加载佣金流水列表，保持与现有 InviteAPI.earningLedgers 契约一致。
final class InviteLedgersController extends GetxController {
  /// 收益流水列表数据源。
  final RxList<InviteEarningLedger> ledgers = <InviteEarningLedger>[].obs;

  /// 页面加载状态；驱动收益明细 loading / retry。
  final RxBool loading = false.obs;

  /// 页面加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadLedgers();
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

  /// 加载收益明细列表。
  Future<void> loadLedgers() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _earningLedgers();
      ledgers.assignAll(result.items);
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 获取收益明细，mock 模式下使用明细页私有样例数据。
  Future<PageResult<InviteEarningLedger>> _earningLedgers() async {
    if (!_useMock) {
      return InviteAPI.earningLedgers();
    }
    final items = await _mock.resolveList<InviteEarningLedger>(
      _mockLedgers,
      mockKey: 'invite.earnings.ledgers',
    );
    return PageResult<InviteEarningLedger>(
      items: items,
      total: items.length,
      hasMore: false,
    );
  }

  static const List<InviteEarningLedger> _mockLedgers =
      <InviteEarningLedger>[
        InviteEarningLedger(
          id: 'ledger_001',
          sourceUserId: '1024',
          orderNo: 'P202606020930',
          amountCents: 780,
          ledgerType: 'DIRECT_MEMBER',
          relationLevel: 1,
          commissionRate: 10,
          agentLevelSnapshot: 1,
          status: 'SETTLED',
          occurredAtText: '2025.05.29 14:41',
        ),
        InviteEarningLedger(
          id: 'ledger_002',
          sourceUserId: '2048',
          orderNo: 'P202606011030',
          amountCents: 1680,
          ledgerType: 'INDIRECT_MEMBER',
          relationLevel: 2,
          commissionRate: 10,
          agentLevelSnapshot: 2,
          status: 'SETTLED',
          occurredAtText: '2025.05.28 10:30',
        ),
      ];
}
