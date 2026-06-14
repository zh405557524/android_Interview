part of 'index.dart';

/// 邀请列表子流程的业务与状态控制类。
///
/// 页面进入时只加载团队概览和邀请记录；筛选与搜索沿用本地处理，不改变当前
/// InviteAPI 的分页和查询契约。
final class InviteRecordsController extends GetxController {
  /// 团队统计卡片使用的邀请概览数据。
  final Rxn<InviteOverview> overview = Rxn<InviteOverview>();

  /// 邀请记录列表数据源。
  final RxList<InviteRecord> records = <InviteRecord>[].obs;

  /// 当前记录筛选条件；`ALL` 为全部，`REGISTERED` 为仅注册，`MEMBER` 为会员。
  final RxString recordFilter = 'ALL'.obs;

  /// 当前搜索关键字，按脱敏手机号本地匹配。
  final RxString recordKeyword = ''.obs;

  /// 页面加载状态；驱动列表页 loading / retry。
  final RxBool loading = false.obs;

  /// 页面加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  /// 搜索输入框控制器；切换筛选时保留搜索词。
  final TextEditingController recordSearchController = TextEditingController();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadRecords();
  }

  @override
  void onClose() {
    recordSearchController.dispose();
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

  /// 按当前筛选条件和搜索关键字得到页面可见的邀请记录。
  List<InviteRecord> get filteredRecords {
    final keyword = recordKeyword.value.trim();
    final filter = recordFilter.value;
    return records
        .where((record) {
          final matchesFilter = switch (filter) {
            'MEMBER' => record.memberCommissionStatus == 'SETTLED',
            'REGISTERED' => record.memberCommissionStatus != 'SETTLED',
            _ => true,
          };
          final matchesKeyword =
              keyword.isEmpty || record.nicknameMasked.contains(keyword);
          return matchesFilter && matchesKeyword;
        })
        .toList(growable: false);
  }

  /// 选择邀请记录筛选条件。
  void selectRecordFilter(String filter) {
    recordFilter.value = filter;
  }

  /// 更新邀请记录搜索关键字。
  void updateRecordKeyword(String value) {
    recordKeyword.value = value;
  }

  /// 加载团队概览和邀请记录。
  Future<void> loadRecords() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await Future.wait<Object>([_overview(), _records()]);
      overview.value = result[0] as InviteOverview;
      records.assignAll((result[1] as PageResult<InviteRecord>).items);
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 获取团队概览，mock 模式下使用列表页私有样例数据。
  Future<InviteOverview> _overview() {
    if (!_useMock) {
      return InviteAPI.overview();
    }
    return _mock.resolve<InviteOverview>(
      _mockOverview,
      mockKey: 'invite.overview',
    );
  }

  /// 获取邀请记录，mock 模式下使用列表页私有样例数据。
  Future<PageResult<InviteRecord>> _records() async {
    if (!_useMock) {
      return InviteAPI.records();
    }
    final items = await _mock.resolveList<InviteRecord>(
      _mockRecords,
      mockKey: 'invite.records',
    );
    return PageResult<InviteRecord>(
      items: items,
      total: items.length,
      hasMore: false,
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

  static const List<InviteRecord> _mockRecords = <InviteRecord>[
    InviteRecord(
      id: 'invite_001',
      nicknameMasked: '198****4280',
      rewardText: '+10 积分',
      status: InviteRewardStatus.granted,
      createdAtText: '2025.05.29 14:41',
      rewardPoints: 10,
      memberCommissionStatus: 'SETTLED',
      bindSource: 'LINK',
    ),
    InviteRecord(
      id: 'invite_002',
      nicknameMasked: '198****4281',
      rewardText: '+10 积分',
      status: InviteRewardStatus.granted,
      createdAtText: '2025.05.29 14:41',
      rewardPoints: 10,
      memberCommissionStatus: 'SETTLED',
      bindSource: 'APP',
    ),
    InviteRecord(
      id: 'invite_003',
      nicknameMasked: '198****4282',
      rewardText: '+10 积分',
      status: InviteRewardStatus.granted,
      createdAtText: '2025.05.29 14:41',
      rewardPoints: 10,
      memberCommissionStatus: 'PENDING',
      bindSource: 'LINK',
    ),
  ];
}
