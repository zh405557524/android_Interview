part of 'index.dart';

/// 任务中心接口适配器。
///
/// 统一封装 App 任务中心概览和签到领取相关后端接口。
abstract class TasksAPI {
  /// 获取当前用户任务中心概览，供 `/task-center` 页面初始化与刷新使用。
  ///
  /// 接口：`GET /api/tasks/center`；返回总积分、签到状态和每日任务列表。
  static Future<TaskCenterOverview> center() async {
    final response = await HttpService.to.get('/api/tasks/center');
    return TaskCenterOverview.fromJson(ApiParser.dataMap(response));
  }

  /// 执行当日签到领取积分。
  ///
  /// 接口：`POST /api/tasks/check-in`；返回签到结果、奖励积分和最新总积分。
  static Future<TaskCheckInResult> checkIn() async {
    final response = await HttpService.to.post('/api/tasks/check-in');
    return TaskCheckInResult.fromJson(ApiParser.dataMap(response));
  }
}
