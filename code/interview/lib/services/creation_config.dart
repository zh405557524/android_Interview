part of 'index.dart';

final class CreationConfigService extends GetxService {
  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<CreationStyle> styles = <CreationStyle>[].obs;
  final RxList<VoiceRole> voices = <VoiceRole>[].obs;

  Future<bool>? _loadingFuture;

  bool get hasStyles => styles.isNotEmpty;
  bool get hasVoices => voices.isNotEmpty;
  bool get hasRequiredConfig => hasStyles && hasVoices;

  Future<bool> load({bool force = false}) {
    if (!force && hasRequiredConfig) {
      return Future<bool>.value(true);
    }
    final loading = _loadingFuture;
    if (loading != null) {
      return loading;
    }

    final future = _load().whenComplete(() {
      _loadingFuture = null;
    });
    _loadingFuture = future;
    return future;
  }

  Future<bool> _load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await Future.wait<Object>([
        _fetchStyles(),
        _fetchVoiceRoles(),
      ]);
      styles.assignAll(result[0] as List<CreationStyle>);
      voices.assignAll(result[1] as List<VoiceRole>);
      return hasRequiredConfig;
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
      return false;
    } catch (_) {
      errorMessage.value = '创作配置加载失败';
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<List<CreationStyle>> _fetchStyles() async {
    if (_useMock) {
      return _mock.resolveList<CreationStyle>(
        _mockStyles,
        mockKey: 'creation.styles',
      );
    }
    final response = await HttpService.to.get('/api/config/styles');
    return _styleItems(response)
        .map(_styleJson)
        .map(CreationStyle.fromJson)
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  Future<List<VoiceRole>> _fetchVoiceRoles() async {
    if (_useMock) {
      return _mock.resolveList<VoiceRole>(
        _mockVoices,
        mockKey: 'creation.voices',
      );
    }
    final response = await HttpService.to.get('/api/config/voices');
    final result = _presetItems(response, 'voices')
        .map(VoiceRole.fromConfigJson)
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
    result.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return result;
  }

  bool get _useMock {
    return Get.isRegistered<ConfigStore>() &&
        Get.find<ConfigStore>().mockEnabled.value;
  }

  MockService get _mock => Get.find<MockService>();

  static List<Map<String, dynamic>> _presetItems(Object? response, String key) {
    final data = _unwrapData(response);
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data[key] is List) {
      items = data[key] as List<dynamic>;
    } else if (data is Map && data[key] is List) {
      items = data[key] as List<dynamic>;
    } else {
      items = _dataList(response);
    }

    return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static List<Map<String, dynamic>> _styleItems(Object? response) {
    final data = _unwrapData(response);
    if (data is Map) {
      final grouped = <Map<String, dynamic>>[];
      grouped
        ..addAll(_styleGroupItems(data, 'narration', CreationMode.narration))
        ..addAll(_styleGroupItems(data, 'trimming', CreationMode.trimming));
      if (grouped.isNotEmpty) {
        return grouped;
      }
      final legacyStyles = data['styles'];
      if (legacyStyles is List) {
        return legacyStyles
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
      }
    }
    return _dataList(
      response,
    ).whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static List<Map<String, dynamic>> _styleGroupItems(
    Map<dynamic, dynamic> data,
    String key,
    CreationMode mode,
  ) {
    final group = data[key];
    if (group is! List) {
      return const <Map<String, dynamic>>[];
    }
    return group.whereType<Map>().map((item) {
      final json = Map<String, dynamic>.from(item);
      json.putIfAbsent('mode', () => mode.name);
      return json;
    }).toList();
  }

  static Map<String, dynamic> _styleJson(Map<String, dynamic> json) {
    final id = _firstText(json, const <String>['id', 'code']);
    final name = _firstText(json, const <String>['name', 'title']);
    final mode = _firstText(json, const <String>['mode']);
    return <String, dynamic>{
      ...json,
      'id': id.isNotEmpty ? id : name,
      'name': name.isNotEmpty ? name : id,
      'mode': mode.isNotEmpty
          ? mode
          : _modeFromTaskType(_firstText(json, const <String>['taskType'])),
      'description': _firstText(json, const <String>['description', 'desc']),
    };
  }

  static Object? _unwrapData(Object? data) {
    if (data is BaseResponse) {
      return data.data;
    }
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  static List<dynamic> _dataList(Object? data) {
    final value = _unwrapData(data);
    if (value is List) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      final items = value['items'] ?? value['list'] ?? value['records'];
      if (items is List) {
        return items;
      }
    }
    if (value is Map) {
      final items = value['items'] ?? value['list'] ?? value['records'];
      if (items is List) {
        return items;
      }
    }
    return const <dynamic>[];
  }

  static String _firstText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && '$value'.trim().isNotEmpty) {
        return '$value'.trim();
      }
    }
    return '';
  }

  static String _modeFromTaskType(String taskType) {
    return taskType.toUpperCase() == 'MASH_UP'
        ? CreationMode.trimming.name
        : CreationMode.narration.name;
  }

  static const List<CreationStyle> _mockStyles = <CreationStyle>[
    CreationStyle(
      id: 'style_real',
      name: '真实解说风格',
      mode: CreationMode.narration,
      description: '适合剧情解说',
    ),
    CreationStyle(
      id: 'style_fast',
      name: '高能快节奏',
      mode: CreationMode.narration,
      description: '适合短视频节奏',
    ),
  ];

  static const List<VoiceRole> _mockVoices = <VoiceRole>[
    VoiceRole(
      id: 'voice_real',
      name: '真实配音',
      description: '通用解说音色',
      emotionTags: <String>['通用'],
    ),
    VoiceRole(
      id: 'voice_warm',
      name: '温暖女声',
      description: '柔和讲述音色',
      emotionTags: <String>['开心'],
    ),
  ];
}
