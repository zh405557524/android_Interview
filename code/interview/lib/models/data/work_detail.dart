import '../../enums/index.dart';
import 'work.dart';

/// 作品详情数据。
///
/// 用于作品详情页展示视频预览、生成参数、下载和过期信息。
final class WorkDetail {
  const WorkDetail({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.videoUrl,
    required this.durationText,
    required this.status,
    required this.workType,
    required this.createdAtText,
    required this.params,
    this.downloadUrl,
    this.expireAtText,
    this.videoVariants = const <WorkVideoVariant>[],
  });

  /// 作品 id。
  final String id;

  /// 作品标题。
  final String title;

  /// 作品封面图地址。
  final String coverUrl;

  /// 视频播放地址。
  final String videoUrl;

  /// 已格式化的视频时长。
  final String durationText;

  /// 作品生成或可用状态。
  final WorkStatus status;

  /// 作品类型，与百度智能集锦 project.type 保持一致。
  final WorkType workType;

  /// 已格式化的创建时间。
  final String createdAtText;

  /// 创作参数展示键值对。
  final Map<String, String> params;

  /// 可选下载地址。
  final String? downloadUrl;

  /// 可选过期时间文案。
  final String? expireAtText;

  /// 多样性生成返回的多个成片地址。
  final List<WorkVideoVariant> videoVariants;

  WorkVideoVariant? videoVariantAt(int index) {
    if (videoVariants.isEmpty) {
      return null;
    }
    if (index < 0 || index >= videoVariants.length) {
      return videoVariants.first;
    }
    return videoVariants[index];
  }

  factory WorkDetail.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'] as Map? ?? const <String, String>{};
    final resources = (json['resources'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
    final variants = _videoVariants(json, resources);
    final firstVariant = variants.isEmpty ? null : variants.first;
    return WorkDetail(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      coverUrl:
          '${json['coverUrl'] ?? firstVariant?.coverUrl ?? _resourceUrl(resources, 'COVER_IMAGE') ?? ''}',
      videoUrl:
          '${firstVariant?.videoUrl ?? json['videoUrl'] ?? json['playbackUrl'] ?? ''}',
      durationText:
          '${json['durationText'] ?? json['duration'] ?? _durationText(resources) ?? ''}',
      status: workStatusFromValue(json['status']),
      workType: workTypeFromValue(json['workType'] ?? json['category']),
      createdAtText:
          '${json['createdAtText'] ?? json['createdAt'] ?? _createdAtText(resources) ?? ''}',
      params: rawParams.map((key, value) => MapEntry('$key', '$value')),
      downloadUrl: firstVariant?.downloadUrl ?? json['downloadUrl'] as String?,
      expireAtText:
          json['expireAtText'] as String? ?? _expireAtText(json['expiredAt']),
      videoVariants: variants,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'videoUrl': videoUrl,
      'durationText': durationText,
      'status': status.name,
      'workType': workType.apiValue,
      'createdAtText': createdAtText,
      'params': params,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (expireAtText != null) 'expireAtText': expireAtText,
      'videoVariants': videoVariants.map((item) => item.toJson()).toList(),
    };
  }
}

/// 作品详情中的单个可播放成片。
final class WorkVideoVariant {
  const WorkVideoVariant({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.coverUrl = '',
    this.downloadUrl,
  });

  final String id;
  final String title;
  final String videoUrl;
  final String coverUrl;
  final String? downloadUrl;

  factory WorkVideoVariant.fromJson(Map<String, dynamic> json, int index) {
    final videoUrl = _firstText(json, const <String>[
      'videoUrl',
      'playbackUrl',
      'url',
      'fileUrl',
      'file_url',
    ]);
    final title = _firstText(json, const <String>['title', 'name', 'label']);
    return WorkVideoVariant(
      id: _firstText(json, const <String>[
        'id',
        'variantId',
        'variant_id',
        'resourceId',
        'resource_id',
      ]).ifEmpty('variant_${index + 1}'),
      title: title.ifEmpty('成片 ${index + 1}'),
      videoUrl: videoUrl,
      coverUrl: _firstText(json, const <String>[
        'coverUrl',
        'cover_url',
        'thumbnailUrl',
        'thumbnail_url',
      ]),
      downloadUrl: _nullableText(
        _firstText(json, const <String>[
          'downloadUrl',
          'download_url',
          'download',
        ]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      'coverUrl': coverUrl,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
    };
  }
}

List<WorkVideoVariant> _videoVariants(
  Map<String, dynamic> json,
  List<Map<String, dynamic>> resources,
) {
  final variants = <WorkVideoVariant>[];
  final seenUrls = <String>{};

  void addVariant(WorkVideoVariant variant) {
    final url = variant.videoUrl.trim();
    if (url.isEmpty || !seenUrls.add(url)) {
      return;
    }
    variants.add(variant);
  }

  final videoUrls = json['videoUrls'] ?? json['video_urls'];
  if (videoUrls is Iterable) {
    for (final item in videoUrls) {
      final index = variants.length;
      if (item is Map) {
        addVariant(
          WorkVideoVariant.fromJson(Map<String, dynamic>.from(item), index),
        );
      } else {
        addVariant(
          WorkVideoVariant(
            id: 'variant_${index + 1}',
            title: '成片 ${index + 1}',
            videoUrl: '$item',
          ),
        );
      }
    }
  }

  for (final key in const <String>['videos', 'outputs']) {
    final items = json[key];
    if (items is! Iterable) {
      continue;
    }
    for (final item in items) {
      final index = variants.length;
      if (item is Map) {
        addVariant(
          WorkVideoVariant.fromJson(Map<String, dynamic>.from(item), index),
        );
      } else {
        addVariant(
          WorkVideoVariant(
            id: 'variant_${index + 1}',
            title: '成片 ${index + 1}',
            videoUrl: '$item',
          ),
        );
      }
    }
  }

  for (final resource in resources) {
    if ('${resource['type'] ?? ''}'.toUpperCase() != 'VIDEO') {
      continue;
    }
    addVariant(WorkVideoVariant.fromJson(resource, variants.length));
  }

  final topLevelVideoUrl = _firstText(json, const <String>[
    'videoUrl',
    'playbackUrl',
    'url',
  ]);
  if (topLevelVideoUrl.isNotEmpty) {
    addVariant(
      WorkVideoVariant(
        id: 'variant_${variants.length + 1}',
        title: '成片 ${variants.length + 1}',
        videoUrl: topLevelVideoUrl,
        coverUrl: _firstText(json, const <String>['coverUrl', 'cover_url']),
        downloadUrl: _nullableText(
          _firstText(json, const <String>['downloadUrl', 'download_url']),
        ),
      ),
    );
  }

  return variants;
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && '$value'.trim().isNotEmpty) {
      return '$value'.trim();
    }
  }
  return '';
}

String? _nullableText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _durationText(List<Map<String, dynamic>> resources) {
  final seconds = _videoResourceValue(resources, 'durationSeconds');
  if (seconds is! num) {
    return null;
  }
  final totalSeconds = seconds.toInt();
  if (totalSeconds <= 0) {
    return null;
  }
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final secs = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${two(hours)}:${two(minutes)}:${two(secs)}';
  }
  return '${two(minutes)}:${two(secs)}';
}

String? _createdAtText(List<Map<String, dynamic>> resources) {
  final value =
      _videoResourceValue(resources, 'createdAt') ??
      (resources.isEmpty ? null : resources.first['createdAt']);
  return _formatDateTime(value);
}

String? _expireAtText(Object? value) {
  final formatted = _formatDateTime(value);
  return formatted == null ? null : '有效期至 $formatted';
}

String? _resourceUrl(List<Map<String, dynamic>> resources, String type) {
  for (final resource in resources) {
    if ('${resource['type'] ?? ''}'.toUpperCase() == type) {
      final url = '${resource['url'] ?? ''}'.trim();
      if (url.isNotEmpty) {
        return url;
      }
    }
  }
  return null;
}

Object? _videoResourceValue(List<Map<String, dynamic>> resources, String key) {
  for (final resource in resources) {
    if ('${resource['type'] ?? ''}'.toUpperCase() == 'VIDEO') {
      return resource[key];
    }
  }
  return null;
}

String? _formatDateTime(Object? value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty) {
    return null;
  }
  final dateTime = DateTime.tryParse(raw);
  if (dateTime == null) {
    return raw;
  }
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

extension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
