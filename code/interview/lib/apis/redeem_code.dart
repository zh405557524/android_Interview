part of 'index.dart';

abstract class RedeemCodeAPI {
  /// 兑换当前用户输入的兑换码。
  ///
  /// 接口：`POST /api/redeem-codes/redeem`。
  static Future<RedeemCodeResult> redeem(String code) async {
    final response = await HttpService.to.post(
      '/api/redeem-codes/redeem',
      data: <String, dynamic>{'code': code},
    );
    return RedeemCodeResult.fromJson(ApiParser.dataMap(response));
  }
}
