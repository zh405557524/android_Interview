/// 邀请收益明细记录。
///
/// 用于收益明细子流程展示直接或间接会员佣金流水。
final class InviteEarningLedger {
  const InviteEarningLedger({
    required this.id,
    required this.sourceUserId,
    required this.orderNo,
    required this.amountCents,
    required this.ledgerType,
    required this.relationLevel,
    required this.commissionRate,
    required this.agentLevelSnapshot,
    required this.status,
    required this.occurredAtText,
  });

  /// 收益流水 id。
  final String id;

  /// 产生收益的来源用户 id。
  final String sourceUserId;

  /// 关联会员订单号。
  final String orderNo;

  /// 本次收益金额，单位为分。
  final int amountCents;

  /// 收益类型，例如直接会员收益或间接会员收益。
  final String ledgerType;

  /// 邀请关系层级，1 为直接，2 为间接。
  final int relationLevel;

  /// 本次佣金比例快照，单位为百分比。
  final int commissionRate;

  /// 产生收益时的代理等级快照。
  final int agentLevelSnapshot;

  /// 收益结算状态。
  final String status;

  /// 已格式化的收益发生时间。
  final String occurredAtText;

  /// 页面展示的收益类型文案。
  String get typeText => ledgerType == 'INDIRECT_MEMBER' ? '间接收益' : '直接收益';

  factory InviteEarningLedger.fromJson(Map<String, dynamic> json) {
    return InviteEarningLedger(
      id: '${json['id'] ?? ''}',
      sourceUserId: '${json['sourceUserId'] ?? ''}',
      orderNo: '${json['orderNo'] ?? ''}',
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      ledgerType: '${json['ledgerType'] ?? ''}',
      relationLevel: (json['relationLevel'] as num?)?.toInt() ?? 0,
      commissionRate: (json['commissionRate'] as num?)?.toInt() ?? 0,
      agentLevelSnapshot: (json['agentLevelSnapshot'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? ''}',
      occurredAtText: '${json['occurredAt'] ?? ''}',
    );
  }
}
