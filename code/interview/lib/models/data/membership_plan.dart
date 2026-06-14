/// 会员购买套餐。
///
/// 用于 VIP 会员页展示周期、价格、权益和推荐角标。
final class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.periodLabel,
    required this.priceText,
    required this.benefits,
    this.badge,
  });

  /// 套餐唯一 id。
  final String id;

  /// 套餐名称。
  final String name;

  /// 套餐周期说明，例如月卡、季卡、年卡。
  final String periodLabel;

  /// 套餐价格展示文案。
  final String priceText;

  /// 套餐权益列表。
  final List<String> benefits;

  /// 可选推荐角标。
  final String? badge;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      periodLabel: '${json['periodLabel'] ?? ''}',
      priceText: '${json['priceText'] ?? ''}',
      benefits: List<String>.from(json['benefits'] as List? ?? const []),
      badge: json['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'periodLabel': periodLabel,
      'priceText': priceText,
      'benefits': benefits,
      if (badge != null) 'badge': badge,
    };
  }
}
