import '../../enums/index.dart';

/// 作品列表项。
///
/// 用于我的作品页展示作品封面、状态、分类和创建时间。
final class Work {
  const Work({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.durationText,
    required this.status,
    required this.workType,
    required this.createdAtText,
  });

  /// 作品 id。
  final String id;

  /// 作品标题。
  final String title;

  /// 作品封面图地址。
  final String coverUrl;

  /// 已格式化的视频时长。
  final String durationText;

  /// 作品生成或可用状态。
  final WorkStatus status;

  /// 作品类型，与百度智能集锦 project.type 保持一致。
  final WorkType workType;

  /// 已格式化的创建时间。
  final String createdAtText;

  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      coverUrl: '${json['coverUrl'] ?? ''}',
      durationText: '${json['durationText'] ?? json['duration'] ?? ''}',
      status: _workStatus(json['status']),
      workType: _workType(json['workType'] ?? json['category']),
      createdAtText: '${json['createdAtText'] ?? json['createdAt'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'durationText': durationText,
      'status': status.name,
      'workType': workType.apiValue,
      'createdAtText': createdAtText,
    };
  }
}

WorkStatus workStatusFromValue(Object? value) => _workStatus(value);

WorkType workTypeFromValue(Object? value) => _workType(value);

WorkStatus _workStatus(Object? value) {
  final normalized = '${value ?? ''}'.trim().toLowerCase();
  return switch (normalized) {
    'active' || 'success' || 'succeeded' || 'completed' => WorkStatus.succeeded,
    'generating' ||
    'running' ||
    'analyzing' ||
    'submitted' => WorkStatus.generating,
    'queued' || 'pending' || 'uploading' => WorkStatus.queued,
    'draft' => WorkStatus.draft,
    'failed' || 'failure' => WorkStatus.failed,
    'expired' => WorkStatus.expired,
    _ => WorkStatus.succeeded,
  };
}

WorkType _workType(Object? value) {
  final normalized = '${value ?? ''}'.trim().toLowerCase();
  return WorkType.values.firstWhere(
    (item) {
      final apiValue = item.apiValue?.toLowerCase();
      return item.name.toLowerCase() == normalized || apiValue == normalized;
    },
    orElse: () => switch (normalized) {
      'video' || 'short_drama' || 'comic_drama' => WorkType.shortSeries,
      'movie' || 'moive' => WorkType.movie,
      'tv' || 'tv_drama' || 'tvseries' => WorkType.tvSeries,
      _ => WorkType.all,
    },
  );
}
