import 'task_center_overview.dart';

/// 用户签到结果。
final class TaskCheckInResult {
  const TaskCheckInResult({
    required this.signedToday,
    required this.firstTime,
    required this.rewardPoints,
    required this.totalPoints,
    required this.consecutiveDays,
    required this.cycleDay,
    required this.days,
  });

  /// 签到接口处理后当天是否处于已签到状态。
  final bool signedToday;

  /// 本次请求是否首次完成今日签到；重复点击时后端返回 false。
  final bool firstTime;

  /// 本次签到实际发放的积分数，重复签到时保持已有记录奖励。
  final int rewardPoints;

  /// 签到处理后的用户可用总积分，用于同步我的页积分状态。
  final int totalPoints;

  /// 签到处理后的连续签到天数。
  final int consecutiveDays;

  /// 签到处理后所在 7 天循环的第几天。
  final int cycleDay;

  /// 签到处理后的 7 天奖励节点状态。
  final List<TaskCheckInDay> days;

  /// 将后端 `POST /api/tasks/check-in` 返回体解析为签到结果。
  factory TaskCheckInResult.fromJson(Map<String, dynamic> json) {
    return TaskCheckInResult(
      signedToday: json['signedToday'] == true,
      firstTime: json['firstTime'] == true,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      consecutiveDays: (json['consecutiveDays'] as num?)?.toInt() ?? 0,
      cycleDay: (json['cycleDay'] as num?)?.toInt() ?? 1,
      days: _list(
        json['days'],
      ).map((item) => TaskCheckInDay.fromJson(_map(item))).toList(),
    );
  }
}

/// 将弱类型 JSON 值安全转成字符串键 Map。
Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

/// 将弱类型 JSON 值安全转成列表，避免接口缺字段导致解析异常。
List<dynamic> _list(Object? value) {
  return value is List ? value : const <dynamic>[];
}
