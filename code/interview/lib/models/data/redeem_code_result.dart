/// 兑换码兑换结果。
final class RedeemCodeResult {
  const RedeemCodeResult({
    required this.code,
    required this.productType,
    this.rewardPoints,
    this.membershipDays,
    this.pointsBalance,
    this.membershipExpiredAt,
    this.message,
  });

  final String code;
  final String productType;
  final int? rewardPoints;
  final int? membershipDays;
  final int? pointsBalance;
  final DateTime? membershipExpiredAt;
  final String? message;

  bool get isPoints => productType.toUpperCase() == 'POINTS';
  bool get isMembership => productType.toUpperCase() == 'MEMBERSHIP';

  String get rewardText {
    if (isPoints) {
      return '获得 ${rewardPoints ?? 0} 积分';
    }
    if (isMembership) {
      return '会员延长 ${membershipDays ?? 0} 天';
    }
    return '兑换成功';
  }

  factory RedeemCodeResult.fromJson(Map<String, dynamic> json) {
    return RedeemCodeResult(
      code: '${json['code'] ?? ''}',
      productType: '${json['productType'] ?? ''}',
      rewardPoints: (json['rewardPoints'] as num?)?.toInt(),
      membershipDays: (json['membershipDays'] as num?)?.toInt(),
      pointsBalance: (json['pointsBalance'] as num?)?.toInt(),
      membershipExpiredAt: _dateTime(
        json['membershipExpiredAt'] ??
            json['membershipExpireAt'] ??
            json['expiredAt'],
      ),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'productType': productType,
      if (rewardPoints != null) 'rewardPoints': rewardPoints,
      if (membershipDays != null) 'membershipDays': membershipDays,
      if (pointsBalance != null) 'pointsBalance': pointsBalance,
      if (membershipExpiredAt != null)
        'membershipExpiredAt': membershipExpiredAt!.toIso8601String(),
      if (message != null) 'message': message,
    };
  }
}

DateTime? _dateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse('$value');
}
