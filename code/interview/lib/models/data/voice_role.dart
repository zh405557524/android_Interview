/// 配音角色配置。
///
/// 用于创作页选择配音人声、情绪和试听资源。
final class VoiceRole {
  const VoiceRole({
    required this.id,
    required this.name,
    required this.description,
    required this.emotionTags,
    this.coverUrl = '',
    this.gender = '',
    this.language = '',
    this.recommend = false,
    this.newVoice = false,
    this.sortOrder = 0,
    this.auditionUrl,
  });

  /// 配音角色唯一 id。
  final String id;

  /// 配音角色展示名称。
  final String name;

  /// 配音角色说明。
  final String description;

  /// 支持的情绪标签。
  final List<String> emotionTags;

  /// 百度返回的音色头像地址。
  final String coverUrl;

  /// 百度音色性别标记，例如 `man` / `woman`。
  final String gender;

  /// 百度音色支持的语言列表原始字符串。
  final String language;

  /// 是否为百度推荐音色。
  final bool recommend;

  /// 是否为百度新音色。
  final bool newVoice;

  /// 后端配置排序值，越小越靠前。
  final int sortOrder;

  /// 可选试听音频地址。
  final String? auditionUrl;

  factory VoiceRole.fromJson(Map<String, dynamic> json) {
    final auditionValue = json['auditionUrl'];
    final auditionText = auditionValue == null ? '' : '$auditionValue'.trim();
    final emotionValues = json['emotionTags'];
    return VoiceRole(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      emotionTags: emotionValues is List
          ? emotionValues.map((item) => '$item').toList()
          : const <String>[],
      coverUrl: '${json['coverUrl'] ?? ''}',
      gender: '${json['gender'] ?? ''}',
      language: '${json['language'] ?? ''}',
      recommend: json['recommend'] == true,
      newVoice: json['newVoice'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      auditionUrl: auditionText.isEmpty ? null : auditionText,
    );
  }

  factory VoiceRole.fromConfigJson(Map<String, dynamic> json) {
    final id = _voiceFirstText(json, const <String>[
      'id',
      'code',
      'voiceId',
      'voice_id',
      'per',
      'voice',
    ]);
    final name = _voiceFirstText(json, const <String>[
      'name',
      'title',
      'voiceName',
      'voice_name',
      'displayName',
      'display_name',
    ]);
    final auditionUrl = _voiceFirstText(json, const <String>[
      'auditionUrl',
      'sampleUrl',
      'sample_url',
      'demoUrl',
      'demo_url',
      'previewUrl',
      'preview_url',
      'url',
    ]);
    return VoiceRole(
      id: id.isNotEmpty ? id : name,
      name: name.isNotEmpty ? name : id,
      description: _voiceFirstText(json, const <String>[
        'description',
        'desc',
        'intro',
        'introduction',
      ]),
      emotionTags: _voiceTextList(
        _voiceFirstValue(json, const <String>[
          'emotionTags',
          'emotion_tags',
          'emotions',
          'emotionList',
          'emotion_list',
          'tags',
        ]),
      ),
      coverUrl: _voiceFirstText(json, const <String>[
        'coverUrl',
        'cover_url',
        'avatarUrl',
        'avatar_url',
        'image',
        'icon',
      ]),
      gender: _voiceFirstText(json, const <String>['gender', 'sex']),
      language: _voiceFirstText(json, const <String>[
        'language',
        'lang',
        'languages',
      ]),
      recommend: _voiceBool(
        _voiceFirstValue(json, const <String>[
          'recommend',
          'recommended',
          'isRecommend',
          'is_recommend',
          'hot',
        ]),
      ),
      newVoice: _voiceBool(
        _voiceFirstValue(json, const <String>[
          'newVoice',
          'new_voice',
          'isNewVoice',
          'is_new_voice',
          'isNew',
          'is_new',
          'new',
        ]),
      ),
      sortOrder: _voiceInt(
        _voiceFirstValue(json, const <String>[
          'sortOrder',
          'sort_order',
          'sort',
          'order',
          'index',
        ]),
      ),
      auditionUrl: auditionUrl.isEmpty ? null : auditionUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'emotionTags': emotionTags,
      'coverUrl': coverUrl,
      'gender': gender,
      'language': language,
      'recommend': recommend,
      'newVoice': newVoice,
      'sortOrder': sortOrder,
      if (auditionUrl != null) 'auditionUrl': auditionUrl,
    };
  }
}

Object? _voiceFirstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    return value;
  }
  return null;
}

String _voiceFirstText(Map<String, dynamic> json, List<String> keys) {
  final value = _voiceFirstValue(json, keys);
  if (value is Iterable) {
    return value
        .map((item) => '$item'.trim())
        .where((item) {
          return item.isNotEmpty;
        })
        .join(',');
  }
  return value == null ? '' : '$value'.trim();
}

List<String> _voiceTextList(Object? value) {
  if (value == null) {
    return const <String>[];
  }
  if (value is Iterable) {
    return value.map(_voiceTagText).where((item) => item.isNotEmpty).toList();
  }
  final text = '$value'.trim();
  if (text.isEmpty) {
    return const <String>[];
  }
  return text
      .split(RegExp(r'[,，;；|/、\s]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _voiceTagText(Object? value) {
  if (value is Map) {
    for (final key in const <String>['name', 'title', 'label', 'value']) {
      final item = value[key];
      if (item != null && '$item'.trim().isNotEmpty) {
        return '$item'.trim();
      }
    }
  }
  return value == null ? '' : '$value'.trim();
}

bool _voiceBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = '${value ?? ''}'.trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

int _voiceInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('${value ?? ''}'.trim()) ?? 0;
}
