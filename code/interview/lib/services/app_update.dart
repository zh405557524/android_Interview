part of 'index.dart';

/// App 版本更新检查与执行服务。
///
/// 该服务只通过调用方传入的 [BuildContext] 展示弹框，避免使用 `Get.context`。
final class AppUpdateService extends GetxService {
  static const MethodChannel _platform = MethodChannel('narrate/app_update');

  final Dio _downloadDio = Dio();

  /// 启动恢复登录后的检查是否已经执行，避免主页面重建时重复弹框。
  bool _startupChecked = false;

  /// 是否已有版本检查正在执行，避免手动点击和登录检查并发弹多次。
  bool _checking = false;

  /// 登录成功后检查版本更新。
  Future<void> checkAfterLogin(BuildContext context) {
    return checkAndPrompt(context, manual: false);
  }

  /// 启动时从本地恢复登录态后，在主页面首帧检查版本更新。
  Future<void> checkAfterStartup(BuildContext context) async {
    if (_startupChecked) {
      return;
    }
    if (!Get.isRegistered<UserStore>() || !Get.find<UserStore>().isLoggedIn) {
      return;
    }
    _startupChecked = true;
    await checkAndPrompt(context, manual: false);
  }

  /// 设置页手动检查版本更新。
  Future<void> checkManually(BuildContext context) {
    return checkAndPrompt(context, manual: true);
  }

  /// 拉取版本策略并按结果展示弹框或无更新提示。
  Future<void> checkAndPrompt(
    BuildContext context, {
    required bool manual,
  }) async {
    if (_checking) {
      return;
    }
    _checking = true;
    try {
      final update = await fetchUpdateInfo();
      if (!update.enabled || !update.updateAvailable) {
        if (manual) {
          CustomToast.text('已是最新版本');
        }
        return;
      }
      if (!context.mounted) {
        return;
      }
      final confirmed = await _AppUpdateDialog.show(context, update);
      if (confirmed == true && context.mounted) {
        await executeUpdate(update);
      }
    } on ApiException catch (error) {
      if (manual) {
        CustomToast.text(error.userMessage);
      }
    } catch (error, stackTrace) {
      AppLogger.error('[AppUpdate] check failed', error, stackTrace);
      if (manual) {
        CustomToast.text('检查更新失败，请稍后重试');
      }
    } finally {
      _checking = false;
    }
  }

  /// 从后端读取当前平台和渠道命中的版本策略。
  Future<AppUpdateInfo> fetchUpdateInfo() async {
    if (Get.isRegistered<ConfigStore>() &&
        Get.find<ConfigStore>().mockEnabled.value) {
      return AppUpdateInfo.disabled;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final platform = _clientPlatform();
    final channel = await _clientChannel(platform);
    final versionCode = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;
    final response = await HttpService.to.get(
      '/api/config/version-update',
      query: <String, dynamic>{
        'platform': platform,
        'channel': channel,
        'versionName': packageInfo.version,
        'versionCode': versionCode,
      },
    );
    return AppUpdateInfo.fromJson(_dataMap(response));
  }

  /// 执行后台配置的升级动作。
  Future<void> executeUpdate(AppUpdateInfo update) async {
    if (!update.hasActionUrl) {
      CustomToast.text('更新地址未配置，请稍后再试');
      return;
    }
    if (update.actionType == AppUpdateActionType.downloadApk &&
        Platform.isAndroid) {
      await _downloadAndInstall(update);
      return;
    }
    await _openExternalUrl(update.actionUrl);
  }

  String _clientPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'ios';
  }

  Future<String> _clientChannel(String platform) async {
    if (platform != 'android') {
      return 'default';
    }
    try {
      final value = await _platform.invokeMethod<String>('getChannel');
      final normalized = value?.trim().toLowerCase();
      return normalized == 'office' ? 'office' : 'store';
    } catch (_) {
      return 'office';
    }
  }

  Future<void> _downloadAndInstall(AppUpdateInfo update) async {
    File? apkFile;
    try {
      CustomToast.loading('准备下载更新...');
      apkFile = await _createTempApk(update.latestVersionCode);
      await _downloadDio.download(
        update.downloadUrl,
        apkFile.path,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total <= 0) {
            CustomToast.loading('正在下载更新...');
            return;
          }
          final progress = (received / total).clamp(0, 1).toDouble();
          CustomToast.showProgress(progress, '正在下载更新...');
        },
      );
      CustomToast.dismiss();
      final installed = await _platform.invokeMethod<bool>(
        'installApk',
        <String, Object?>{'path': apkFile.path},
      );
      if (installed == true) {
        CustomToast.text('请按系统提示完成安装');
      } else {
        CustomToast.text('无法唤起安装，请稍后重试');
      }
    } on DioException catch (error) {
      AppLogger.error('[AppUpdate] download failed', error);
      CustomToast.dismiss();
      CustomToast.text(_downloadErrorMessage(error));
    } catch (error, stackTrace) {
      AppLogger.error('[AppUpdate] install failed', error, stackTrace);
      CustomToast.dismiss();
      CustomToast.text('安装失败，请稍后重试');
    }
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final opened = await _platform.invokeMethod<bool>(
        'openUrl',
        <String, Object?>{'url': url},
      );
      if (opened != true) {
        CustomToast.text('无法打开更新地址');
      }
    } catch (error, stackTrace) {
      AppLogger.error('[AppUpdate] open url failed', error, stackTrace);
      CustomToast.text('无法打开更新地址');
    }
  }

  Future<File> _createTempApk(int latestVersionCode) async {
    final directory = await getTemporaryDirectory();
    final version = latestVersionCode <= 0 ? 'latest' : '$latestVersionCode';
    final file = File('${directory.path}/narrate_update_$version.apk');
    if (await file.exists()) {
      await file.delete();
    }
    return file;
  }

  String _downloadErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络设置';
    }
    return '更新包下载失败，请稍后重试';
  }

  Map<String, dynamic> _dataMap(BaseResponse response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }
}

class _AppUpdateDialog extends StatelessWidget {
  const _AppUpdateDialog({required this.update});

  final AppUpdateInfo update;

  static Future<bool?> show(BuildContext context, AppUpdateInfo update) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) => _AppUpdateDialog(update: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !update.forceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            width: 319.w,
            decoration: BoxDecoration(
              color: const Color(0xFF0B100C),
              border: Border.all(
                color: CustomTheme.primary.withValues(alpha: 0.12),
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 150.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CustomTheme.primary.withValues(alpha: 0.22),
                          CustomTheme.primary.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        update.title.isEmpty ? '发现新版本' : update.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        update.latestVersionName.isEmpty
                            ? '新版本'
                            : 'v${update.latestVersionName}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CustomTheme.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        update.message.isEmpty ? '请升级到最新版本' : update.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFB8B8B8),
                          fontSize: 14.sp,
                          height: 22 / 14,
                        ),
                      ),
                      if (update.releaseNotes.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _ReleaseNotes(notes: update.releaseNotes),
                      ],
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          if (!update.forceUpdate) ...[
                            Expanded(
                              child: _DialogButton(
                                label: '稍后再说',
                                primary: false,
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Expanded(
                            child: _DialogButton(
                              label:
                                  update.actionType ==
                                      AppUpdateActionType.downloadApk
                                  ? '立即下载'
                                  : '立即升级',
                              primary: true,
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 150.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final note in notes)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  '- $note',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 13.sp,
                    height: 20 / 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? CustomTheme.primary
              : Colors.white.withValues(alpha: 0.08),
          foregroundColor: primary ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
