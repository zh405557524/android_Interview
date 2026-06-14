/// 积分充值套餐。
///
/// 用于积分充值页展示积分数量、价格和营销角标。
final class PointsPackage {
  const PointsPackage({
    required this.id,
    required this.points,
    required this.priceText,
    this.badge,
  });

  /// 套餐唯一 id。
  final String id;

  /// 购买后到账积分数量。
  final int points;

  /// 价格展示文案。
  final String priceText;

  /// 可选营销角标。
  final String? badge;

  factory PointsPackage.fromJson(Map<String, dynamic> json) {
    return PointsPackage(
      id: '${json['id'] ?? ''}',
      points: (json['points'] as num?)?.toInt() ?? 0,
      priceText: '${json['priceText'] ?? ''}',
      badge: json['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'points': points,
      'priceText': priceText,
      if (badge != null) 'badge': badge,
    };
  }
}
