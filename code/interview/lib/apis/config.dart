part of 'index.dart';

abstract class ConfigAPI {
  /// 获取后端配置预设。
  ///
  /// 候选接口：`GET /api/config/presets`。
  /// 可通过 [type] 获取创作风格、配音角色等指定配置。
  static Future<List<AppPreset>> presets({String? type}) async {
    final response = await HttpService.to.get(
      '/api/config/presets',
      query: type == null ? null : <String, dynamic>{'type': type},
    );
    return ApiParser.dataList(response).map((item) {
      return AppPreset.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  /// 获取协议、隐私政策、充值规则等静态内容。
  ///
  /// 候选接口：`GET /api/config/static-page/{key}`。
  /// 返回页面标题和正文；内容缺失态由静态页 Controller 处理。
  static Future<AppStaticPage> staticPage(String key) async {
    final response = await HttpService.to.get('/api/config/static-page/$key');
    return AppStaticPage.fromJson(ApiParser.dataMap(response));
  }

  /// 检查当前客户端版本是否需要升级。
  ///
  /// 候选接口：`GET /api/config/version-update`。
  /// [platform] 取 `android` 或 `ios`，[channel] 用于区分 Android 官方渠道和商店渠道。
  static Future<AppUpdateInfo> checkVersionUpdate({
    required String platform,
    required String channel,
    required String versionName,
    required int versionCode,
  }) async {
    final response = await HttpService.to.get(
      '/api/config/version-update',
      query: <String, dynamic>{
        'platform': platform,
        'channel': channel,
        'versionName': versionName,
        'versionCode': versionCode,
      },
    );
    return AppUpdateInfo.fromJson(ApiParser.dataMap(response));
  }
}
