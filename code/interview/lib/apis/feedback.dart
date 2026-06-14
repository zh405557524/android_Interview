part of 'index.dart';

abstract class FeedbackAPI {
  /// 提交用户意见反馈。
  ///
  /// 候选接口：`POST /api/feedback`。
  /// 只提交类型、内容和联系方式；附件上传能力待后端和供应商确定。
  static Future<void> submit(FeedbackParams params) async {
    await HttpService.to.post('/api/feedback/datafeed', data: params.toJson());
  }
}
