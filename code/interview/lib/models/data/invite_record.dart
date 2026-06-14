import '../../enums/index.dart';

/// 单条邀请奖励记录。
///
/// 用于邀请好友页展示邀请对象、奖励和发放状态。
final class InviteRecord {
  const InviteRecord({
    required this.id,
    required this.nicknameMasked,
    required this.rewardText,
    required this.status,
    required this.createdAtText,
    this.rewardPoints = 0,
    this.memberCommissionStatus = '',
    this.bindSource = '',
  });

  /// 邀请记录 id。
  final String id;

  /// 被邀请用户脱敏昵称。
  final String nicknameMasked;

  /// 奖励展示文案，例如 `+20 积分`。
  final String rewardText;

  /// 奖励发放状态。
  final InviteRewardStatus status;

  /// 已格式化的邀请时间。
  final String createdAtText;

  /// 注册奖励积分数量。
  final int rewardPoints;

  /// 被邀请人会员佣金状态；`SETTLED` 表示已产生会员收益。
  final String memberCommissionStatus;

  /// 邀请关系绑定来源，例如邀请链接或 App 内填写。
  final String bindSource;

  factory InviteRecord.fromJson(Map<String, dynamic> json) {
    final rewardPoints = (json['rewardPoints'] as num?)?.toInt() ?? 0;
    return InviteRecord(
      id: '${json['id'] ?? ''}',
      nicknameMasked:
          '${json['nicknameMasked'] ?? json['inviteeName'] ?? _inviteeLabel(json)}',
      rewardText:
          '${json['rewardText'] ?? (rewardPoints > 0 ? '+$rewardPoints 积分' : '待奖励')}',
      status: _rewardStatus(json['status'] ?? json['rewardStatus']),
      createdAtText:
          '${json['createdAtText'] ?? json['boundAt'] ?? json['createdAt'] ?? ''}',
      rewardPoints: rewardPoints,
      memberCommissionStatus: '${json['memberCommissionStatus'] ?? ''}',
      bindSource: '${json['bindSource'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nicknameMasked': nicknameMasked,
      'rewardText': rewardText,
      'status': status.name,
      'createdAtText': createdAtText,
      'rewardPoints': rewardPoints,
      'memberCommissionStatus': memberCommissionStatus,
      'bindSource': bindSource,
    };
  }
}

InviteRewardStatus _rewardStatus(Object? value) {
  final normalized = '$value'.trim().toUpperCase();
  if (normalized == 'REWARDED' || normalized == 'GRANTED') {
    return InviteRewardStatus.granted;
  }
  if (normalized == 'DISABLED' || normalized == 'INVALID') {
    return InviteRewardStatus.invalid;
  }
  return InviteRewardStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => InviteRewardStatus.pending,
  );
}

String _inviteeLabel(Map<String, dynamic> json) {
  final userId = '${json['inviteeUserId'] ?? ''}'.trim();
  return userId.isEmpty ? '受邀好友' : '用户 $userId';
}
