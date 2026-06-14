part of 'index.dart';

abstract class UserAPI {
  /// 获取当前用户资料。
  ///
  /// 候选接口：`GET /api/user/profile`。
  /// 返回手机号脱敏信息、邀请码、积分和会员状态。
  static Future<UserProfile> profile() async {
    final response = await HttpService.to.get('/api/user/profile');
    return UserProfile.fromJson(ApiParser.dataMap(response));
  }

  /// 退出当前账号。
  ///
  /// 候选接口：`POST /api/user/logout`。
  /// 只通知后端注销会话；本地 token 和用户状态由业务 Controller 清理。
  static Future<void> logout() async {
    await HttpService.to.post('/api/user/logout');
  }

  /// 提交账号注销申请。
  ///
  /// 候选接口：`POST /api/user/delete-request`。
  /// 注销冷静期和审核流程以后端正式规则为准。
  static Future<void> requestDelete() async {
    await HttpService.to.post('/api/user/delete-request');
  }
}
