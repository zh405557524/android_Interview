/// 用户积分账户。
///
/// 用于展示当前可用积分和冻结积分。
final class PointsAccount {
  const PointsAccount({required this.balance, required this.frozen});

  /// 可用积分余额。
  final int balance;

  /// 冻结或处理中积分。
  final int frozen;

  factory PointsAccount.fromJson(Map<String, dynamic> json) {
    return PointsAccount(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      frozen: (json['frozen'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'balance': balance, 'frozen': frozen};
  }
}
