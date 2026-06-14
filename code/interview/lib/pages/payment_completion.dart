import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../apis/index.dart';
import '../models/index.dart';
import '../routes/index.dart';
import '../store/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';
import 'main/index.dart';

abstract final class PaymentCompletion {
  static const int _profileRefreshAttempts = 3;
  static const Duration _profileRefreshDelay = Duration(milliseconds: 600);

  static Future<bool> refreshUserAndOpenAccount({
    required UserStore userStore,
    required String successMessage,
    required String tag,
  }) async {
    try {
      final profile = await _refreshProfileWithRetry();
      userStore.setProfile(profile);
      _openAccountTab(tag);
      CustomToast.text(successMessage);
      return true;
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        '支付成功，用户信息刷新失败，请稍后查看',
        error: error,
        stackTrace: stackTrace,
        tag: tag,
      );
      return false;
    }
  }

  static Future<bool> refreshUserAndClosePage({
    required BuildContext context,
    required UserStore userStore,
    required String successMessage,
    required String tag,
  }) async {
    try {
      final profile = await _refreshProfileWithRetry();
      userStore.setProfile(profile);
      CustomToast.text(successMessage);
      if (context.mounted && Navigator.canPop(context)) {
        await Navigator.maybePop(context);
      }
      return true;
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        '支付成功，用户信息刷新失败，请稍后查看',
        error: error,
        stackTrace: stackTrace,
        tag: tag,
      );
      return false;
    }
  }

  static Future<UserProfile> _refreshProfileWithRetry() async {
    ApiException? latestError;
    StackTrace? latestStackTrace;

    for (var attempt = 0; attempt < _profileRefreshAttempts; attempt += 1) {
      try {
        return await UserAPI.profile();
      } on ApiException catch (error, stackTrace) {
        latestError = error;
        latestStackTrace = stackTrace;
        if (attempt < _profileRefreshAttempts - 1) {
          await Future<void>.delayed(_profileRefreshDelay);
        }
      }
    }

    Error.throwWithStackTrace(latestError!, latestStackTrace!);
  }

  static void _openAccountTab(String tag) {
    final mainController = Get.isRegistered<MainController>()
        ? Get.find<MainController>()
        : Get.put(MainController(), permanent: true);
    mainController.showAccountTab();

    if (_goMainIfPossible()) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_goMainIfPossible()) {
        AppLogger.info('$tag payment completed, account tab selected');
      }
    });
  }

  static bool _goMainIfPossible() {
    final context = CustomRouter.navigatorKey.currentContext ?? Get.context;
    if (context == null || !context.mounted) {
      return false;
    }
    context.goNamed(RouteName.main);
    return true;
  }
}
