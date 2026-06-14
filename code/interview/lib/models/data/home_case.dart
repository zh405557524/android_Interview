/// 首页案例卡片数据。
///
/// 用于展示热门案例和分类筛选后的样例作品。
final class HomeCase {
  const HomeCase({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryCode,
    required this.displayLabel,
    required this.durationText,
    required this.coverUrl,
    this.videoUrl = '',
    this.styleName = '',
    this.styleApplicableText = '',
    this.styleExplanationText = '',
    this.relatedTemplateId = '',
  });

  /// 案例唯一 id。
  final String id;

  /// 案例标题。
  final String title;

  /// 案例所属展示分类。
  final String category;

  /// 案例所属分类编码。
  final String categoryCode;

  /// 卡片左上角展示标签。
  final String displayLabel;

  /// 已格式化的视频时长文案。
  final String durationText;

  /// 案例封面图地址。
  final String coverUrl;

  /// 案例视频地址；后台上传资源通常为 `/uploads/...` 相对路径。
  final String videoUrl;

  /// 案例对应的解说风格名称。
  final String styleName;

  /// 解说风格适用场景。
  final String styleApplicableText;

  /// 解说风格解释说明。
  final String styleExplanationText;

  /// 关联模板 ID，用于后续快速创作。
  final String relatedTemplateId;

  factory HomeCase.fromJson(Map<String, dynamic> json) {
    return HomeCase(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      category: '${json['category'] ?? ''}',
      categoryCode: '${json['categoryCode'] ?? ''}',
      displayLabel:
          '${json['displayLabel'] ?? json['durationText'] ?? json['duration'] ?? ''}',
      durationText:
          '${json['durationText'] ?? json['displayLabel'] ?? json['duration'] ?? ''}',
      coverUrl: '${json['coverUrl'] ?? ''}',
      videoUrl: '${json['videoUrl'] ?? ''}',
      styleName: '${json['styleName'] ?? ''}',
      styleApplicableText: '${json['styleApplicableText'] ?? ''}',
      styleExplanationText: '${json['styleExplanationText'] ?? ''}',
      relatedTemplateId: '${json['relatedTemplateId'] ?? ''}',
    );
  }

  HomeCase copyWith({
    String? id,
    String? title,
    String? category,
    String? categoryCode,
    String? displayLabel,
    String? durationText,
    String? coverUrl,
    String? videoUrl,
    String? styleName,
    String? styleApplicableText,
    String? styleExplanationText,
    String? relatedTemplateId,
  }) {
    return HomeCase(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryCode: categoryCode ?? this.categoryCode,
      displayLabel: displayLabel ?? this.displayLabel,
      durationText: durationText ?? this.durationText,
      coverUrl: coverUrl ?? this.coverUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      styleName: styleName ?? this.styleName,
      styleApplicableText: styleApplicableText ?? this.styleApplicableText,
      styleExplanationText: styleExplanationText ?? this.styleExplanationText,
      relatedTemplateId: relatedTemplateId ?? this.relatedTemplateId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'category': category,
      'categoryCode': categoryCode,
      'displayLabel': displayLabel,
      'durationText': durationText,
      'coverUrl': coverUrl,
      'videoUrl': videoUrl,
      'styleName': styleName,
      'styleApplicableText': styleApplicableText,
      'styleExplanationText': styleExplanationText,
      'relatedTemplateId': relatedTemplateId,
    };
  }
}

/// 首页热门案例分类。
///
/// 后台可维护分类名称和排序，App 首页按后端返回动态渲染。
final class HomeCaseCategory {
  const HomeCaseCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.hotTab,
  });

  final int id;
  final String code;
  final String name;
  final int sortOrder;
  final bool hotTab;

  factory HomeCaseCategory.fromJson(Map<String, dynamic> json) {
    return HomeCaseCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: '${json['categoryCode'] ?? json['code'] ?? ''}',
      name: '${json['categoryName'] ?? json['name'] ?? ''}',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      hotTab: json['hotTab'] == true || json['isHotTab'] == true,
    );
  }
}
