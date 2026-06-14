import '../../enums/index.dart';

/// 创作风格配置。
///
/// 用于控制生成任务采用解说、精剪等不同处理模式。
final class CreationStyle {
  const CreationStyle({
    required this.id,
    required this.name,
    required this.mode,
    required this.description,
  });

  /// 风格唯一 id。
  final String id;

  /// 页面展示名称。
  final String name;

  /// 风格所属创作模式。
  final CreationMode mode;

  /// 风格说明文案。
  final String description;

  factory CreationStyle.fromJson(Map<String, dynamic> json) {
    return CreationStyle(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      mode: _creationMode(json['mode']),
      description: '${json['description'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'mode': mode.name,
      'description': description,
    };
  }
}

CreationMode _creationMode(Object? value) {
  return CreationMode.values.firstWhere(
    (item) => item.name == value,
    orElse: () => CreationMode.narration,
  );
}
