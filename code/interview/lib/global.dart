import 'dart:async';

import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'plugins/index.dart';
import 'services/index.dart';
import 'store/index.dart';
import 'utils/index.dart';

class Global {
  Global._();

  static const String localServerAddress = AppConstants.localServerAddress;
  static const String testServerAddress = AppConstants.testServerAddress;
  static const String prodServerAddress = AppConstants.prodServerAddress;
  static const int currentServerAddressType = 1; // 1=local, 2=test, 3=prod
  static const bool isDebug = true;

  static String serverAddress = _resolveServerAddress(currentServerAddressType);

  static PackageInfo? _packageInfo;

  static String get appName => _packageInfo?.appName ?? AppConstants.appName;
  static String get version => _packageInfo?.version ?? '0.0.0';
  static String get buildNumber => _packageInfo?.buildNumber ?? '0';

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();

    await Get.putAsync<StorageService>(() => StorageService().init());

    Get.put<EventService>(EventService(), permanent: true);
    Get.put<MockService>(MockService(), permanent: true);
    Get.put<PaymentGatewayService>(PaymentGatewayService(), permanent: true);
    Get.put<AliyunNumberAuthService>(
      AliyunNumberAuthService(),
      permanent: true,
    );
    final configStore = Get.put<ConfigStore>(
      ConfigStore(
        apiBaseUrl: serverAddress,
        appEnvironment: currentServerAddressType.toString(),
      ),
      permanent: true,
    );
    final httpService = Get.put<HttpService>(HttpService(), permanent: true);
    final userStore = Get.put<UserStore>(UserStore(), permanent: true);
    Get.put<CreationStore>(CreationStore(), permanent: true);
    Get.put<CreationConfigService>(CreationConfigService(), permanent: true);
    final loginService = Get.put<LoginService>(LoginService(), permanent: true);
    Get.put<AppUpdateService>(AppUpdateService(), permanent: true);

    httpService.setBaseUrl(configStore.apiBaseUrl.value);
    if (userStore.restoreSession()) {
      httpService.setToken(userStore.token.value);
      unawaited(loginService.refreshSessionForStartup());
    }
  }

  static Future<void> refreshRestoredSession({
    required ConfigStore configStore,
    required HttpService httpService,
    required UserStore userStore,
  }) async {
    if (!Get.isRegistered<LoginService>()) {
      Get.put<LoginService>(LoginService(), permanent: true);
    }
    await Get.find<LoginService>().refreshSessionForStartup();
  }

  static String _resolveServerAddress(int type) {
    return switch (type) {
      2 => testServerAddress,
      3 => prodServerAddress,
      _ => localServerAddress,
    };
  }
}
