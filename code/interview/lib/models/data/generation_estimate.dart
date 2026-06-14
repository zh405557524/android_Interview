/// 生成任务提交前的积分预估结果。
///
/// 用于确认弹层展示消耗，并判断是否需要权益 / 积分拦截。
final class GenerationEstimate {
  const GenerationEstimate({
    required this.pointCost,
    required this.enough,
    required this.message,
  });

  /// 本次生成预计消耗积分。
  final int pointCost;

  /// 当前用户积分或权益是否足够。
  final bool enough;

  /// 后端返回的预估说明文案。
  final String message;

  factory GenerationEstimate.fromJson(Map<String, dynamic> json) {
    return GenerationEstimate(
      pointCost: (json['pointCost'] as num?)?.toInt() ?? 0,
      enough: json['enough'] == true,
      message: '${json['message'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pointCost': pointCost,
      'enough': enough,
      'message': message,
    };
  }
}
