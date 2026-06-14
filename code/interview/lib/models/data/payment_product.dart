import '../../enums/index.dart';
import 'membership_plan.dart';
import 'points_package.dart';

/// 支付产品数据。
///
/// 对应后端 `tb_product`，用于把会员卡套和积分积套转换成前端展示套餐。
final class PaymentProduct {
  const PaymentProduct({
    required this.id,
    required this.name,
    required this.productType,
    required this.priceText,
    required this.givePoints,
    this.cardType,
    this.memberDays = 0,
    this.pointsExpireDays,
  });

  /// 产品 ID。
  final String id;

  /// 产品名称。
  final String name;

  /// 产品类型：1=会员卡套，2=积分积套。
  final int productType;

  /// 卡套类型：1=月卡，2=季卡，3=年卡。
  final int? cardType;

  /// 价格展示文案。
  final String priceText;

  /// 会员有效期天数。
  final int memberDays;

  /// 赠送或到账积分。
  final int givePoints;

  /// 积分有效期天数。
  final int? pointsExpireDays;

  PaymentPurpose get purpose {
    return productType == 1 ? PaymentPurpose.membership : PaymentPurpose.points;
  }

  factory PaymentProduct.fromJson(Map<String, dynamic> json) {
    return PaymentProduct(
      id: _productId(json),
      name: '${json['productName'] ?? json['name'] ?? ''}',
      productType: (json['productType'] as num?)?.toInt() ?? 0,
      cardType: (json['cardType'] as num?)?.toInt(),
      priceText: _priceText(json['price'] ?? json['priceText']),
      memberDays: (json['memberDays'] as num?)?.toInt() ?? 0,
      givePoints:
          (json['givePoints'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt() ??
          0,
      pointsExpireDays: (json['pointsExpireDays'] as num?)?.toInt(),
    );
  }

  MembershipPlan toMembershipPlan() {
    final benefits = <String>[
      if (givePoints > 0) '赠送 $givePoints 积分',
      if (memberDays > 0) '会员有效期 $memberDays 天',
      '高阶模型和更多功能',
      '会员专属配音免费使用',
    ];
    return MembershipPlan(
      id: id,
      name: name,
      periodLabel: _periodLabel(),
      priceText: priceText,
      benefits: benefits,
      badge: cardType == 3 ? '推荐' : null,
    );
  }

  PointsPackage toPointsPackage() {
    return PointsPackage(id: id, points: givePoints, priceText: priceText);
  }

  String _periodLabel() {
    return switch (cardType) {
      1 => '月卡',
      2 => '季卡',
      3 => '年卡',
      _ => memberDays > 0 ? '$memberDays 天' : '会员',
    };
  }

  static String _productId(Map<String, dynamic> json) {
    for (final key in const <String>['id', 'productId', 'product_id']) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      final text = '$value'.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _priceText(Object? value) {
    if (value == null) {
      return '¥0';
    }
    if (value is num) {
      final hasDecimal = value % 1 != 0;
      return '¥${value.toStringAsFixed(hasDecimal ? 2 : 0)}';
    }
    final raw = '$value'.trim();
    if (raw.isEmpty) {
      return '¥0';
    }
    if (raw.startsWith('¥')) {
      return raw;
    }
    final number = num.tryParse(raw);
    if (number != null) {
      final hasDecimal = number % 1 != 0;
      return '¥${number.toStringAsFixed(hasDecimal ? 2 : 0)}';
    }
    return raw;
  }
}
