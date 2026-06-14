part of 'index.dart';

final class SettingsController extends GetxController {
  final UserStore userStore = Get.find<UserStore>();
  final HttpService _http = Get.find<HttpService>();

  final RxString versionText = '获取中'.obs;
  final RxBool clearingCache = false.obs;
  final RxBool checkingUpdate = false.obs;
  final RxBool submitting = false.obs;

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadVersion();
  }

  Future<void> loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      versionText.value = 'v${info.version}';
    } catch (_) {
      versionText.value = 'v1.0.0';
    }
  }

  Future<void> clearCache() async {
    if (clearingCache.value) {
      return;
    }
    clearingCache.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      CustomToast.text('缓存已清理');
    } catch (_) {
      CustomToast.text('清理失败，请稍后重试');
    } finally {
      clearingCache.value = false;
    }
  }

  /// 手动检查版本更新；检查中禁用入口避免重复弹出更新弹框。
  Future<void> checkUpdate(BuildContext context) async {
    if (checkingUpdate.value) {
      return;
    }
    checkingUpdate.value = true;
    try {
      if (!Get.isRegistered<AppUpdateService>()) {
        CustomToast.text('检查更新服务暂不可用');
        return;
      }
      await Get.find<AppUpdateService>().checkManually(context);
    } finally {
      checkingUpdate.value = false;
    }
  }

  /// 退出当前账号。
  ///
  /// 成功后清理本地会话与 HTTP 鉴权头，并返回 `true` 交给页面执行回首页导航；
  /// 失败时保留当前页面并返回 `false`，方便用户重试。
  Future<bool> logout() async {
    if (submitting.value) {
      return false;
    }
    submitting.value = true;
    try {
      if (_useMock) {
        await _mock.resolve<bool>(true, mockKey: 'user.logout');
      } else {
        await UserAPI.logout();
      }
      await userStore.clearSession();
      _http.setToken(null);
      CustomToast.text('已退出登录');
      return true;
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
      return false;
    } finally {
      submitting.value = false;
    }
  }

  Future<bool> requestDeleteAccount() async {
    if (submitting.value) {
      return false;
    }
    submitting.value = true;
    try {
      if (_useMock) {
        await _mock.resolve<bool>(true, mockKey: 'user.deleteAccount');
      } else {
        await UserAPI.requestDelete();
      }
      await userStore.clearSession();
      _http.setToken(null);
      CustomToast.text('账号已注销');
      return true;
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
