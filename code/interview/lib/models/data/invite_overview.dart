/// 邀请好友页概览数据。
///
/// 包含邀请码、奖励规则和累计奖励信息。
final class InviteOverview {
  const InviteOverview({
    required this.inviteCode,
    required this.ruleText,
    required this.totalRewards,
    this.inviteLink = '',
    this.invitedCount = 0,
    this.todayNewInvitedCount = 0,
    this.rewardedCount = 0,
    this.memberCount = 0,
    this.todayNewMemberCount = 0,
    this.agentLevel = 1,
    this.directInviteCount = 0,
    this.directCommissionRate = 10,
    this.indirectCommissionEnabled = false,
    this.indirectCommissionRate = 10,
    this.totalEarningsCents = 0,
    this.withdrawableCents = 0,
    this.minWithdrawCents = 100,
  });

  /// 当前用户邀请码。
  final String inviteCode;

  /// 邀请奖励规则说明。
  final String ruleText;

  /// 当前用户累计邀请奖励积分。
  final int totalRewards;

  /// 当前用户邀请链接；素材接口为空时也可作为推广链接兜底。
  final String inviteLink;

  /// 当前用户累计邀请人数。
  final int invitedCount;

  /// 今日新增邀请人数。
  final int todayNewInvitedCount;

  /// 已获得注册奖励的人数。
  final int rewardedCount;

  /// 团队中已开通会员的人数。
  final int memberCount;

  /// 今日新增会员人数。
  final int todayNewMemberCount;

  /// 当前个人代理等级，页面展示为推广达人 V 等级。
  final int agentLevel;

  /// 当前用户直接邀请人数。
  final int directInviteCount;

  /// 直接会员收益佣金比例，单位为百分比。
  final int directCommissionRate;

  /// 后台是否开启间接收益。
  final bool indirectCommissionEnabled;

  /// 间接收益佣金比例，单位为百分比。
  final int indirectCommissionRate;

  /// 当前累计邀请收益金额，单位为分。
  final int totalEarningsCents;

  /// 当前可提现收益金额，单位为分。
  final int withdrawableCents;

  /// 最低提现金额，单位为分。
  final int minWithdrawCents;

  factory InviteOverview.fromJson(Map<String, dynamic> json) {
    return InviteOverview(
      inviteCode: '${json['inviteCode'] ?? ''}',
      inviteLink: '${json['inviteLink'] ?? json['visitUrl'] ?? ''}',
      ruleText: '${json['ruleText'] ?? json['ruleSummary'] ?? ''}',
      totalRewards:
          (json['totalRewards'] as num?)?.toInt() ??
          (json['rewardPoints'] as num?)?.toInt() ??
          0,
      invitedCount: (json['invitedCount'] as num?)?.toInt() ?? 0,
      todayNewInvitedCount:
          (json['todayNewInvitedCount'] as num?)?.toInt() ?? 0,
      rewardedCount: (json['rewardedCount'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      todayNewMemberCount: (json['todayNewMemberCount'] as num?)?.toInt() ?? 0,
      agentLevel: (json['agentLevel'] as num?)?.toInt() ?? 1,
      directInviteCount: (json['directInviteCount'] as num?)?.toInt() ?? 0,
      directCommissionRate:
          (json['directCommissionRate'] as num?)?.toInt() ?? 10,
      indirectCommissionEnabled: json['indirectCommissionEnabled'] == true,
      indirectCommissionRate:
          (json['indirectCommissionRate'] as num?)?.toInt() ?? 10,
      totalEarningsCents: (json['totalEarningsCents'] as num?)?.toInt() ?? 0,
      withdrawableCents: (json['withdrawableCents'] as num?)?.toInt() ?? 0,
      minWithdrawCents: (json['minWithdrawCents'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inviteCode': inviteCode,
      'inviteLink': inviteLink,
      'ruleText': ruleText,
      'totalRewards': totalRewards,
      'invitedCount': invitedCount,
      'todayNewInvitedCount': todayNewInvitedCount,
      'rewardedCount': rewardedCount,
      'memberCount': memberCount,
      'todayNewMemberCount': todayNewMemberCount,
      'agentLevel': agentLevel,
      'directInviteCount': directInviteCount,
      'directCommissionRate': directCommissionRate,
      'indirectCommissionEnabled': indirectCommissionEnabled,
      'indirectCommissionRate': indirectCommissionRate,
      'totalEarningsCents': totalEarningsCents,
      'withdrawableCents': withdrawableCents,
      'minWithdrawCents': minWithdrawCents,
    };
  }
}
