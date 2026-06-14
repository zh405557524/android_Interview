/// 邀请收益汇总数据。
///
/// 用于收益入口、提现和提现记录子流程展示金额汇总，金额单位均为分。
final class InviteEarningSummary {
  const InviteEarningSummary({
    required this.todayEarningsCents,
    required this.yesterdayEarningsCents,
    required this.totalEarningsCents,
    required this.withdrawableCents,
    required this.withdrawingCents,
    required this.paidCents,
  });

  /// 今日新增邀请收益金额，单位为分。
  final int todayEarningsCents;

  /// 昨日邀请收益金额，单位为分。
  final int yesterdayEarningsCents;

  /// 累计邀请收益金额，单位为分。
  final int totalEarningsCents;

  /// 当前可提现收益金额，单位为分。
  final int withdrawableCents;

  /// 已提交但未完成打款的提现中金额，单位为分。
  final int withdrawingCents;

  /// 已成功打款金额，单位为分。
  final int paidCents;

  factory InviteEarningSummary.fromJson(Map<String, dynamic> json) {
    return InviteEarningSummary(
      todayEarningsCents: (json['todayEarningsCents'] as num?)?.toInt() ?? 0,
      yesterdayEarningsCents:
          (json['yesterdayEarningsCents'] as num?)?.toInt() ?? 0,
      totalEarningsCents: (json['totalEarningsCents'] as num?)?.toInt() ?? 0,
      withdrawableCents: (json['withdrawableCents'] as num?)?.toInt() ?? 0,
      withdrawingCents: (json['withdrawingCents'] as num?)?.toInt() ?? 0,
      paidCents: (json['paidCents'] as num?)?.toInt() ?? 0,
    );
  }
}
