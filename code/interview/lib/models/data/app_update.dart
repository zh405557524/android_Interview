/// App 版本更新动作类型。
enum AppUpdateActionType {
  /// Android 官方渠道下载 APK 后唤起安装。
  downloadApk,

  /// 跳转应用商店或外部下载页。
  appStore;

  /// 将后端动作字符串转换为客户端枚举。
  static AppUpdateActionType fromValue(Object? value) {
    return '${value ?? ''}'.toUpperCase() == 'DOWNLOAD_APK'
        ? AppUpdateActionType.downloadApk
        : AppUpdateActionType.appStore;
  }
}

/// App 版本更新检查结果。
///
/// 服务于启动/登录检查和设置页手动检查；只包含弹框与升级动作所需信息。
final class AppUpdateInfo {
  const AppUpdateInfo({
    required this.enabled,
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.actionType,
    required this.downloadUrl,
    required this.storeUrl,
    required this.title,
    required this.message,
    required this.releaseNotes,
  });

  /// 后台版本更新总开关是否开启。
  final bool enabled;

  /// 当前客户端版本是否低于后台配置的最新版本。
  final bool updateAvailable;

  /// 是否强制更新；强制更新弹框不可手动关闭。
  final bool forceUpdate;

  /// 后台配置的最新展示版本号。
  final String latestVersionName;

  /// 后台配置的最新构建号，用于和本地 buildNumber 比较。
  final int latestVersionCode;

  /// 命中的升级动作：下载安装包或跳应用商店。
  final AppUpdateActionType actionType;

  /// Android 官方渠道 APK 下载地址。
  final String downloadUrl;

  /// 应用商店或外部下载页地址。
  final String storeUrl;

  /// 更新弹框标题。
  final String title;

  /// 更新弹框正文说明。
  final String message;

  /// 更新说明列表。
  final List<String> releaseNotes;

  /// 当前策略是否可以执行升级动作。
  bool get hasActionUrl {
    return switch (actionType) {
      AppUpdateActionType.downloadApk => downloadUrl.trim().isNotEmpty,
      AppUpdateActionType.appStore => storeUrl.trim().isNotEmpty,
    };
  }

  /// 当前动作使用的目标地址。
  String get actionUrl {
    return switch (actionType) {
      AppUpdateActionType.downloadApk => downloadUrl.trim(),
      AppUpdateActionType.appStore => storeUrl.trim(),
    };
  }

  /// 将后端 `GET /api/config/version-update` 返回体解析为版本更新信息。
  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      enabled: json['enabled'] == true,
      updateAvailable: json['updateAvailable'] == true,
      forceUpdate: json['forceUpdate'] == true,
      latestVersionName: '${json['latestVersionName'] ?? ''}',
      latestVersionCode: (json['latestVersionCode'] as num?)?.toInt() ?? 0,
      actionType: AppUpdateActionType.fromValue(json['actionType']),
      downloadUrl: '${json['downloadUrl'] ?? ''}',
      storeUrl: '${json['storeUrl'] ?? ''}',
      title: '${json['title'] ?? '发现新版本'}',
      message: '${json['message'] ?? '请升级到最新版本'}',
      releaseNotes: _stringList(json['releaseNotes']),
    );
  }

  /// 关闭更新能力时的本地兜底结果。
  static const disabled = AppUpdateInfo(
    enabled: false,
    updateAvailable: false,
    forceUpdate: false,
    latestVersionName: '',
    latestVersionCode: 0,
    actionType: AppUpdateActionType.appStore,
    downloadUrl: '',
    storeUrl: '',
    title: '发现新版本',
    message: '请升级到最新版本',
    releaseNotes: <String>[],
  );
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? <String>[] : <String>[text];
}
