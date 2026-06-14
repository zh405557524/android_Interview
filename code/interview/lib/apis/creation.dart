part of 'index.dart';

abstract class CreationAPI {
  /// 获取可用创作风格。
  ///
  /// 接口：`GET /api/config/styles`。
  /// 后端按“视频解说 / 视频精剪”分组返回百度模板，前端解析为扁平列表给现有 UI 使用。
  static Future<List<CreationStyle>> fetchStyles() async {
    final response = await HttpService.to.get('/api/config/styles');
    return _styleItems(response)
        .map(_styleJson)
        .map(CreationStyle.fromJson)
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  /// 获取可用配音角色。
  ///
  /// 接口：`GET /api/config/voices`。
  /// 音色来自后端数据库 preset.voices，后台管理端可手动从百度刷新这份缓存。
  static Future<List<VoiceRole>> fetchVoiceRoles() async {
    final response = await HttpService.to.get('/api/config/voices');
    final voices = _presetItems(response, 'voices')
        .map(VoiceRole.fromConfigJson)
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
    voices.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return voices;
  }

  static List<Map<String, dynamic>> _presetItems(Object? response, String key) {
    final data = ApiParser.unwrapData(response);
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data[key] is List) {
      items = data[key] as List<dynamic>;
    } else if (data is Map && data[key] is List) {
      items = data[key] as List<dynamic>;
    } else {
      items = ApiParser.dataList(response);
    }

    return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static List<Map<String, dynamic>> _styleItems(Object? response) {
    final data = ApiParser.unwrapData(response);
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
    return ApiParser.dataList(
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
}
