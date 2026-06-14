part of 'index.dart';

final class PointsLedgerController extends GetxController {
  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<PointsLedgerItem> items = <PointsLedgerItem>[].obs;

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    if (items.isEmpty) {
      return ViewState.empty;
    }
    return ViewState.success;
  }

  @override
  void onInit() {
    super.onInit();
    loadLedger();
  }

  Future<void> loadLedger({bool silent = false}) async {
    if (!silent) {
      loading.value = true;
    }
    errorMessage.value = null;
    try {
      final result = await _ledger();
      items.assignAll(result.items);
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

  Future<void> refreshOnEnter() {
    if (loading.value) {
      return Future<void>.value();
    }
    return loadLedger(silent: items.isNotEmpty);
  }

  Future<PageResult<PointsLedgerItem>> _ledger() async {
    if (!_useMock) {
      return PointsAPI.ledger();
    }
    final items = await _mock.resolveList<PointsLedgerItem>(
      _mockLedger,
      mockKey: 'points.ledger',
    );
    return PageResult<PointsLedgerItem>(
      items: items,
      total: items.length,
      hasMore: false,
    );
  }

  static const List<PointsLedgerItem> _mockLedger = <PointsLedgerItem>[
    PointsLedgerItem(
      id: 'ledger_001',
      title: '任务名称',
      dateText: '2026.5.16',
      amount: -20,
      direction: PointDirection.expense,
    ),
    PointsLedgerItem(
      id: 'ledger_002',
      title: '任务名称',
      dateText: '2026.5.16',
      amount: 100,
      direction: PointDirection.income,
    ),
    PointsLedgerItem(
      id: 'ledger_003',
      title: '任务名称',
      dateText: '2026.5.16',
      amount: -20,
      direction: PointDirection.expense,
    ),
  ];
}
