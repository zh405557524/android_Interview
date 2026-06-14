part of 'index.dart';

/// 系统权限访问入口。
///
/// 参考 `clip-flutter` 的 `Access.photos` 形态，把权限申请集中到工具类里，
/// 避免每个页面重复处理 iOS limited、Android 分版本媒体权限和设置页跳转。
abstract final class Access {
  /// 测试环境覆盖 Android SDK 版本，避免 widget 测试依赖真实设备通道。
  @visibleForTesting
  static Future<int> Function()? debugAndroidSdkIntProvider;

  /// 测试环境覆盖当前平台，避免改动 Flutter 全局 debug 平台变量。
  @visibleForTesting
  static TargetPlatform? debugTargetPlatform;

  /// 测试环境覆盖权限状态读取。
  @visibleForTesting
  static Future<List<PermissionStatus>> Function(List<Permission> permissions)?
  debugPermissionStatusProvider;

  /// 测试环境覆盖系统权限申请。
  @visibleForTesting
  static Future<Map<Permission, PermissionStatus>> Function(
    List<Permission> permissions,
  )?
  debugPermissionRequestProvider;

  /// 测试环境覆盖打开系统设置，避免触发原生通道。
  @visibleForTesting
  static VoidCallback? debugOpenSettingsHandler;

  /// 清理测试覆盖项，避免不同测试之间互相污染。
  @visibleForTesting
  static void resetDebugOverrides() {
    debugAndroidSdkIntProvider = null;
    debugTargetPlatform = null;
    debugPermissionStatusProvider = null;
    debugPermissionRequestProvider = null;
    debugOpenSettingsHandler = null;
  }

  /// 申请照片/视频素材读取权限。
  ///
  /// iOS 的视频选择依赖相册权限，用户选择“有限访问”也可以继续使用；
  /// Android 13 起图片、视频权限拆分，业务里需要读取视频素材，所以同时兼容
  /// `photos` 和 `videos`，低版本继续走存储权限。
  ///
  /// 返回 `true` 表示权限可用，并会执行可选的 [callback]；返回 `false`
  /// 表示用户拒绝或当前页面已不可用。
  static Future<bool> photos(
    BuildContext context, [
    FutureOr<void> Function()? callback,
  ]) async {
    return _requestMediaAccess(
      context,
      callback: callback,
      androidPermissionsForSdk: (sdkInt) => sdkInt >= 33
          ? const <Permission>[Permission.photos, Permission.videos]
          : const <Permission>[Permission.storage],
      rationaleMessage: '存储权限说明：\n为实现素材导入、封面读取、视频上传和生成解说，需要访问您设备中的照片和视频文件。',
      deniedMessage: '请允许访问您的相册和媒体文件',
      iosDeniedMessage: '请允许访问您的相册',
    );
  }

  /// 申请视频素材读取权限。
  ///
  /// Android 13 起只请求视频权限，避免为了选择视频额外触发图片权限；
  /// 未授权时先展示业务用途说明 Banner，用户点击继续后才触发系统权限申请。
  static Future<bool> videos(
    BuildContext context, [
    FutureOr<void> Function()? callback,
  ]) async {
    return _requestMediaAccess(
      context,
      callback: callback,
      androidPermissionsForSdk: (sdkInt) => sdkInt >= 33
          ? const <Permission>[Permission.videos]
          : const <Permission>[Permission.storage],
      rationaleMessage: '存储权限说明：\n为选择本地视频、生成缩略图并上传用于生成视频解说，需要访问您设备中的视频文件。',
      deniedMessage: '请允许访问您的视频文件',
      iosDeniedMessage: '请允许访问您的视频',
    );
  }

  /// 申请把生成视频保存到系统相册所需的写入权限。
  ///
  /// Android 10 起系统允许 App 通过 MediaStore 写入自己创建的视频，不需要读取用户相册；
  /// Android 9 及以下仍需要存储写入权限。iOS 使用 add-only 权限，只申请“添加到照片”能力。
  static Future<bool> saveVideoToGallery(
    BuildContext context, [
    FutureOr<void> Function()? callback,
  ]) async {
    if (_targetPlatform == TargetPlatform.iOS) {
      return _requestSinglePermissionAccess(
        context,
        permission: Permission.photosAddOnly,
        rationaleMessage: '相册保存权限说明：\n为将生成完成的视频保存到系统相册，需要获得添加照片和视频的权限。',
        deniedMessage: '请允许添加视频到您的相册',
        callback: callback,
      );
    }

    if (_targetPlatform == TargetPlatform.android) {
      final sdkInt = await _androidSdkInt();
      if (sdkInt >= 29) {
        await callback?.call();
        return true;
      }
      if (!context.mounted) {
        return false;
      }
      return _requestSinglePermissionAccess(
        context,
        permission: Permission.storage,
        rationaleMessage: '存储权限说明：\n为将生成完成的视频保存到系统相册，需要访问设备存储空间。',
        deniedMessage: '请允许访问设备存储空间后再保存视频',
        callback: callback,
      );
    }

    await callback?.call();
    return true;
  }

  /// 展示去系统设置的提示。
  ///
  /// iOS/Android 在用户拒绝权限后，后续再次请求可能不会再弹系统授权框，
  /// 因此这里明确引导用户进入 App 设置页重新开启。
  static void showPhotosDialog(BuildContext context, String message) {
    if (_targetPlatform == TargetPlatform.iOS) {
      showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) {
          return CupertinoAlertDialog(
            title: const Text('无法访问照片'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openSettings();
                },
                child: const Text('去设置'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('权限提示'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openSettings();
              },
              child: const Text('设置'),
            ),
          ],
        );
      },
    );
  }

  static void openSettings() {
    final handler = debugOpenSettingsHandler;
    if (handler != null) {
      handler();
      return;
    }
    openAppSettings();
  }

  static Future<bool> _requestMediaAccess(
    BuildContext context, {
    required List<Permission> Function(int sdkInt) androidPermissionsForSdk,
    required String rationaleMessage,
    required String deniedMessage,
    required String iosDeniedMessage,
    FutureOr<void> Function()? callback,
  }) async {
    if (_targetPlatform == TargetPlatform.iOS) {
      final current = await Permission.photos.status;
      if (_isMediaGranted(current)) {
        await callback?.call();
        return true;
      }
      if (!context.mounted) {
        return false;
      }
      final confirmed = await _showPermissionInfoBanner(
        context,
        rationaleMessage,
      );
      if (!confirmed || !context.mounted) {
        return false;
      }
      final result = await _requestPermission(Permission.photos);
      if (_isMediaGranted(result)) {
        await callback?.call();
        return true;
      }
      if (context.mounted) {
        showPhotosDialog(context, iosDeniedMessage);
      }
      return false;
    }

    if (_targetPlatform != TargetPlatform.android) {
      await callback?.call();
      return true;
    }

    final sdkInt = await _androidSdkInt();
    final permissions = androidPermissionsForSdk(sdkInt);
    final statuses = await _permissionStatuses(permissions);
    if (statuses.any(_isMediaGranted)) {
      await callback?.call();
      return true;
    }

    if (!context.mounted) {
      return false;
    }
    final confirmed = await _showPermissionInfoBanner(
      context,
      rationaleMessage,
    );
    if (!confirmed || !context.mounted) {
      return false;
    }

    final requested = await _requestPermissions(permissions);
    if (requested.values.any(_isMediaGranted)) {
      await callback?.call();
      return true;
    }

    if (context.mounted) {
      showPhotosDialog(context, deniedMessage);
    }
    return false;
  }

  static Future<bool> _showPermissionInfoBanner(
    BuildContext context,
    String message,
  ) {
    final completer = Completer<bool>();
    var removed = false;
    late OverlayEntry overlayEntry;

    void complete(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
      if (!removed) {
        removed = true;
        overlayEntry.remove();
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: _PermissionInfoBanner(
            message: message,
            onCancel: () => complete(false),
            onConfirm: () => complete(true),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(overlayEntry);
    return completer.future;
  }

  static Future<bool> _requestSinglePermissionAccess(
    BuildContext context, {
    required Permission permission,
    required String rationaleMessage,
    required String deniedMessage,
    FutureOr<void> Function()? callback,
  }) async {
    final current = (await _permissionStatuses(<Permission>[permission])).first;
    if (_isMediaGranted(current)) {
      await callback?.call();
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    final confirmed = await _showPermissionInfoBanner(
      context,
      rationaleMessage,
    );
    if (!confirmed || !context.mounted) {
      return false;
    }
    final result = await _requestPermission(permission);
    if (_isMediaGranted(result)) {
      await callback?.call();
      return true;
    }
    if (context.mounted) {
      showPhotosDialog(context, deniedMessage);
    }
    return false;
  }

  static Future<int> _androidSdkInt() async {
    final provider = debugAndroidSdkIntProvider;
    if (provider != null) {
      return provider();
    }
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt;
  }

  static Future<List<PermissionStatus>> _permissionStatuses(
    List<Permission> permissions,
  ) {
    final provider = debugPermissionStatusProvider;
    if (provider != null) {
      return provider(permissions);
    }
    return Future.wait(permissions.map((permission) => permission.status));
  }

  static Future<PermissionStatus> _requestPermission(Permission permission) {
    final provider = debugPermissionRequestProvider;
    if (provider != null) {
      return provider(<Permission>[
        permission,
      ]).then((statuses) => statuses[permission] ?? PermissionStatus.denied);
    }
    return permission.request();
  }

  static Future<Map<Permission, PermissionStatus>> _requestPermissions(
    List<Permission> permissions,
  ) {
    final provider = debugPermissionRequestProvider;
    if (provider != null) {
      return provider(permissions);
    }
    return permissions.request();
  }

  static bool _isMediaGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  static TargetPlatform get _targetPlatform {
    return debugTargetPlatform ?? defaultTargetPlatform;
  }
}

/// 申请系统权限前展示的顶部用途说明。
class _PermissionInfoBanner extends StatefulWidget {
  const _PermissionInfoBanner({
    required this.message,
    required this.onCancel,
    required this.onConfirm,
  });

  /// 权限用途说明文案。
  final String message;

  /// 用户取消授权申请。
  final VoidCallback onCancel;

  /// 用户同意继续触发系统授权。
  final VoidCallback onConfirm;

  @override
  State<_PermissionInfoBanner> createState() => _PermissionInfoBannerState();
}

class _PermissionInfoBannerState extends State<_PermissionInfoBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss(VoidCallback callback) async {
    if (_controller.status != AnimationStatus.dismissed) {
      await _controller.reverse();
    }
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CustomTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: CustomTheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: CustomTheme.textPrimary,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _dismiss(widget.onCancel),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _dismiss(widget.onConfirm),
                          style: FilledButton.styleFrom(
                            backgroundColor: CustomTheme.primary,
                            foregroundColor: Colors.black,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('继续'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
