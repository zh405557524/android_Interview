part of 'index.dart';

abstract class PointsAPI {
  /// 获取积分流水分页。
  ///
  /// 接口：`GET /api/tbPoint/pointList`。
  /// 积分余额由 `/api/user/profile` 返回的 pointsBalance 提供。
  static Future<PageResult<PointsLedgerItem>> ledger({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await HttpService.to.get(
      '/api/tbPoint/pointList',
      query: <String, dynamic>{'pageNo': page, 'pageSize': pageSize},
    );
    return ApiParser.pageResult<PointsLedgerItem>(
      response,
      PointsLedgerItem.fromJson,
    );
  }
}
