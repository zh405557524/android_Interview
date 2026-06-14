/// 积分任务中心总览。
final class TaskCenterOverview {
  const TaskCenterOverview({
    required this.enabled,
    required this.totalPoints,
    required this.checkIn,
    required this.dailyTasks,
  });

  /// 任务中心是否启用；关闭时页面可展示兜底状态但不允许领取签到积分。
  final bool enabled;

  /// 当前用户可用总积分，用于顶部积分胶囊展示并同步到用户状态。
  final int totalPoints;

  /// 连续签到模块的当前状态与 7 天奖励展示数据。
  final TaskCheckInOverview checkIn;

  /// 每日任务列表；第一版只使用邀请好友任务，不展示广告任务。
  final List<TaskCenterItem> dailyTasks;

  /// 从每日任务中挑出邀请好友任务，供第一版任务卡片直接渲染。
  TaskCenterItem? get inviteTask {
    for (final task in dailyTasks) {
      if (task.code == 'INVITE_FRIEND' || task.routeName == 'invite') {
        return task;
      }
    }
    return dailyTasks.isEmpty ? null : dailyTasks.first;
  }

  /// 将后端 `GET /api/tasks/center` 返回体解析为任务中心总览。
  factory TaskCenterOverview.fromJson(Map<String, dynamic> json) {
    return TaskCenterOverview(
      enabled: json['enabled'] != false,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      checkIn: TaskCheckInOverview.fromJson(
        _map(json['checkIn'] ?? json['checkin']),
      ),
      dailyTasks: _list(
        json['dailyTasks'] ?? json['tasks'],
      ).map((item) => TaskCenterItem.fromJson(_map(item))).toList(),
    );
  }
}

/// 连续签到区域的概览数据。
final class TaskCheckInOverview {
  const TaskCheckInOverview({
    required this.signedToday,
    required this.consecutiveDays,
    required this.cycleDay,
    required this.todayRewardPoints,
    required this.days,
  });

  /// 用户当天是否已经完成签到，用于控制按钮禁用和文案。
  final bool signedToday;

  /// 当前连续签到天数，后端按 Asia/Shanghai 自然日计算。
  final int consecutiveDays;

  /// 当前所在 7 天循环的第几天，用于高亮今日奖励点位。
  final int cycleDay;

  /// 今日签到可领取的积分数。
  final int todayRewardPoints;

  /// 7 天奖励点位列表，驱动签到卡片横向节点。
  final List<TaskCheckInDay> days;

  /// 将后端签到概览 JSON 解析为页面可直接消费的数据。
  factory TaskCheckInOverview.fromJson(Map<String, dynamic> json) {
    return TaskCheckInOverview(
      signedToday: json['signedToday'] == true,
      consecutiveDays: (json['consecutiveDays'] as num?)?.toInt() ?? 0,
      cycleDay: (json['cycleDay'] as num?)?.toInt() ?? 1,
      todayRewardPoints: (json['todayRewardPoints'] as num?)?.toInt() ?? 0,
      days: _list(
        json['days'],
      ).map((item) => TaskCheckInDay.fromJson(_map(item))).toList(),
    );
  }
}

/// 连续签到 7 天奖励中的单个天数节点。
final class TaskCheckInDay {
  const TaskCheckInDay({
    required this.day,
    required this.rewardPoints,
    required this.checked,
    required this.current,
  });

  /// 7 天循环中的天序号，从 1 开始。
  final int day;

  /// 当前天数节点对应的奖励积分。
  final int rewardPoints;

  /// 当前天数节点是否已经签到完成。
  final bool checked;

  /// 当前天数节点是否是今日应展示的高亮节点。
  final bool current;

  /// 将后端签到天数节点 JSON 解析为 UI 节点数据。
  factory TaskCheckInDay.fromJson(Map<String, dynamic> json) {
    return TaskCheckInDay(
      day: (json['day'] as num?)?.toInt() ?? 1,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      checked: json['checked'] == true,
      current: json['current'] == true,
    );
  }
}

/// 每日任务列表项。
final class TaskCenterItem {
  const TaskCenterItem({
    required this.code,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.rewardText,
    required this.actionText,
    required this.routeName,
    required this.completed,
    required this.enabled,
  });

  /// 任务编码；邀请任务固定为 `INVITE_FRIEND`。
  final String code;

  /// 任务主标题，用于每日任务卡片左侧第一行。
  final String title;

  /// 任务说明文案，用于展示完成条件。
  final String description;

  /// 任务目标值，例如邀请好友目标人数。
  final int target;

  /// 当前完成进度，页面会与目标值组合成 `progressText`。
  final int progress;

  /// 奖励展示文案，例如 `+10/人`。
  final String rewardText;

  /// 操作按钮文案，例如 `去邀请`。
  final String actionText;

  /// App 内目标路由标识；邀请任务从任务中心直达推广素材页。
  final String routeName;

  /// 任务是否已完成，用于后续扩展完成态展示。
  final bool completed;

  /// 任务是否启用；关闭时按钮禁用但保留展示能力。
  final bool enabled;

  /// 展示给用户的完成进度文本。
  String get progressText => '${progress.clamp(0, target)}/$target';

  /// 将后端每日任务 JSON 解析为任务列表项。
  factory TaskCenterItem.fromJson(Map<String, dynamic> json) {
    return TaskCenterItem(
      code: '${json['code'] ?? ''}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      target: (json['target'] as num?)?.toInt() ?? 1,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      rewardText: '${json['rewardText'] ?? ''}',
      actionText: '${json['actionText'] ?? '去完成'}',
      routeName: '${json['routeName'] ?? ''}',
      completed: json['completed'] == true,
      enabled: json['enabled'] != false,
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
