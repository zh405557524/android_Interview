/// 邀请收益提现记录。
///
/// 用于提现记录子流程展示提现金额、收款账号和审核/打款状态。
final class InviteWithdrawal {
  const InviteWithdrawal({
    required this.id,
    required this.amountCents,
    required this.channel,
    required this.accountNoMasked,
    required this.accountName,
    required this.status,
    required this.reviewRemark,
    required this.createdAtText,
  });

  /// 提现记录 id。
  final String id;

  /// 提现金额，单位为分。
  final int amountCents;

  /// 提现渠道，例如支付宝。
  final String channel;

  /// 脱敏后的提现账号。
  final String accountNoMasked;

  /// 收款人姓名。
  final String accountName;

  /// 提现审核或打款状态。
  final String status;

  /// 审核备注或驳回原因。
  final String reviewRemark;

  /// 已格式化的提现申请时间。
  final String createdAtText;

  /// 页面展示的提现状态文案。
  String get statusText {
    return switch (status) {
      'PENDING_REVIEW' => '待审核',
      'APPROVED' => '待打款',
      'REJECTED' => '已驳回',
      'PAID' => '已打款',
      'PAY_FAILED' => '打款失败',
      _ => status,
    };
  }

  factory InviteWithdrawal.fromJson(Map<String, dynamic> json) {
    return InviteWithdrawal(
      id: '${json['id'] ?? ''}',
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      channel: '${json['channel'] ?? ''}',
      accountNoMasked: '${json['accountNoMasked'] ?? ''}',
      accountName: '${json['accountName'] ?? ''}',
      status: '${json['status'] ?? ''}',
      reviewRemark: '${json['reviewRemark'] ?? ''}',
      createdAtText: '${json['createdAt'] ?? ''}',
    );
  }
}
