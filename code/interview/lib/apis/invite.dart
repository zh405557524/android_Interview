part of 'index.dart';

abstract class InviteAPI {
  /// 获取邀请概览。
  ///
  /// 候选接口：`GET /api/invite/overview`。
  /// 返回邀请码、邀请规则和累计奖励；分享 SDK 由业务层占位处理。
  static Future<InviteOverview> overview() async {
    final response = await HttpService.to.get('/api/invite/overview');
    return InviteOverview.fromJson(ApiParser.dataMap(response));
  }

  /// 获取邀请记录分页。
  ///
  /// 候选接口：`GET /api/invite/records`。
  /// 返回邀请好友奖励记录；分页继续使用 [PageResult] 包装。
  static Future<PageResult<InviteRecord>> records({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    final response = await HttpService.to.get(
      '/api/invite/records',
      query: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (keyword?.trim().isNotEmpty == true) 'keyword': keyword!.trim(),
      },
    );
    return ApiParser.pageResult<InviteRecord>(response, InviteRecord.fromJson);
  }

  /// 绑定当前用户的邀请人。
  ///
  /// 候选接口：`POST /api/invite/bind`。
  /// 一个账号只允许绑定一次；提交失败时由业务层保留用户已输入的邀请码。
  static Future<InviteOverview> bind(String inviteCode) async {
    final response = await HttpService.to.post(
      '/api/invite/bind',
      data: <String, dynamic>{'inviteCode': inviteCode},
    );
    return InviteOverview.fromJson(ApiParser.dataMap(response));
  }

  /// 获取推广素材。
  ///
  /// 候选接口：`GET /api/invite/materials`。
  /// 返回邀请链接、海报文案和下载落地页等推广页展示数据。
  static Future<InviteMaterial> materials() async {
    final response = await HttpService.to.get('/api/invite/materials');
    return InviteMaterial.fromJson(ApiParser.dataMap(response));
  }

  /// 获取邀请收益汇总。
  ///
  /// 候选接口：`GET /api/invite/earnings/summary`。
  /// 返回今日、昨日、累计、可提现、提现中和已打款金额，单位均为分。
  static Future<InviteEarningSummary> earningSummary() async {
    final response = await HttpService.to.get('/api/invite/earnings/summary');
    return InviteEarningSummary.fromJson(ApiParser.dataMap(response));
  }

  /// 获取邀请收益明细分页。
  ///
  /// 候选接口：`GET /api/invite/earnings/ledgers`。
  /// 可通过 [ledgerType] 请求后端类型筛选；当前页面仍以本地展示为主。
  static Future<PageResult<InviteEarningLedger>> earningLedgers({
    int page = 1,
    int pageSize = 20,
    String? ledgerType,
  }) async {
    final response = await HttpService.to.get(
      '/api/invite/earnings/ledgers',
      query: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (ledgerType?.trim().isNotEmpty == true)
          'ledgerType': ledgerType!.trim(),
      },
    );
    return ApiParser.pageResult<InviteEarningLedger>(
      response,
      InviteEarningLedger.fromJson,
    );
  }

  /// 创建提现申请。
  ///
  /// 候选接口：`POST /api/invite/withdrawals`。
  /// [amountCents] 单位为分；账号和协议确认由提现子流程 Controller 先校验。
  static Future<InviteWithdrawal> createWithdrawal({
    required int amountCents,
    required String channel,
    required String accountNo,
    required String accountName,
    required bool agreementAccepted,
  }) async {
    final response = await HttpService.to.post(
      '/api/invite/withdrawals',
      data: <String, dynamic>{
        'amountCents': amountCents,
        'channel': channel,
        'accountNo': accountNo,
        'accountName': accountName,
        'agreementAccepted': agreementAccepted,
      },
    );
    return InviteWithdrawal.fromJson(ApiParser.dataMap(response));
  }

  /// 获取提现记录分页。
  ///
  /// 候选接口：`GET /api/invite/withdrawals`。
  /// 返回提现金额、账号脱敏信息、审核状态和创建时间。
  static Future<PageResult<InviteWithdrawal>> withdrawals({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await HttpService.to.get(
      '/api/invite/withdrawals',
      query: <String, dynamic>{'page': page, 'pageSize': pageSize},
    );
    return ApiParser.pageResult<InviteWithdrawal>(
      response,
      InviteWithdrawal.fromJson,
    );
  }
}
