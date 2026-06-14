part of 'index.dart';

abstract final class ApiParser {
  /// 从统一响应或兼容 Map 中取出业务 `data`。
  ///
  /// API 方法用于适配候选接口包装结构；不在这里处理 mock / real 分支。
  static Object? unwrapData(Object? data) {
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

  /// 将响应 `data` 转成模型构造函数可消费的 Map。
  ///
  /// 响应不是 Map 时返回空 Map，避免 API 方法散落类型兜底逻辑。
  static Map<String, dynamic> dataMap(Object? data) {
    final value = unwrapData(data);
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  /// 将响应 `data` 转成列表。
  ///
  /// 兼容 `data` 本身为 List，以及 `items` / `list` / `records` 分页字段。
  static List<dynamic> dataList(Object? data) {
    final value = unwrapData(data);
    if (value is List) {
      return value;
    }
    if (value is Map<String, dynamic> && value['items'] is List) {
      return value['items'] as List;
    }
    if (value is Map<String, dynamic> && value['list'] is List) {
      return value['list'] as List;
    }
    if (value is Map<String, dynamic> && value['records'] is List) {
      return value['records'] as List;
    }
    if (value is Map && value['items'] is List) {
      return value['items'] as List;
    }
    if (value is Map && value['list'] is List) {
      return value['list'] as List;
    }
    if (value is Map && value['records'] is List) {
      return value['records'] as List;
    }
    return const <dynamic>[];
  }

  /// 将分页响应转成统一 [PageResult]。
  ///
  /// 兼容 `items` / `list` / `records` 列表字段，并读取 `total`、`hasMore`。
  static PageResult<T> pageResult<T>(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final value = unwrapData(data);
    final items = dataList(value).map((item) {
      return fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
    if (value is Map) {
      return PageResult<T>(
        items: items,
        total: (value['total'] as num?)?.toInt() ?? items.length,
        hasMore:
            value['hasMore'] == true ||
            _hasMoreFromPage(
              current: (value['current'] as num?)?.toInt(),
              pages: (value['pages'] as num?)?.toInt(),
            ),
      );
    }
    return PageResult<T>(items: items, total: items.length, hasMore: false);
  }

  static bool _hasMoreFromPage({required int? current, required int? pages}) {
    if (current == null || pages == null) {
      return false;
    }
    return current < pages;
  }
}
