/// 后端下发的通用配置预设。
///
/// 用于承载创作风格、配音角色等可配置枚举型内容。
final class AppPreset {
  const AppPreset({
    required this.key,
    required this.title,
    required this.values,
  });

  /// 配置唯一标识，例如 `creation_styles`。
  final String key;

  /// 配置在管理端或页面上的展示标题。
  final String title;

  /// 配置值列表，具体含义由 [key] 决定。
  final List<String> values;

  factory AppPreset.fromJson(Map<String, dynamic> json) {
    return AppPreset(
      key: '${json['key'] ?? ''}',
      title: '${json['title'] ?? ''}',
      values: List<String>.from(json['values'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'key': key, 'title': title, 'values': values};
  }
}
