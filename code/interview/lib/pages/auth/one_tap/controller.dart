part of '../index.dart';

/// 一键登录提交：取运营商 token 并调后端换会话。
///
/// 是否展示一键页由 [AuthController.oneTapAvailable] 与 [AuthController.mode] 决定。
final class OneTapLoginController {
  OneTapLoginController({required AuthController owner}) : _owner = owner;

  final AuthController _owner;

  /// 是否正在提交一键登录。
  final RxBool submitting = false.obs;

  AliyunNumberAuthService get _numberAuth =>
      Get.isRegistered<AliyunNumberAuthService>()
      ? Get.find<AliyunNumberAuthService>()
      : AliyunNumberAuthService();

  /// 一键页主号码文案。
  String get phoneLabel {
    final phone = _owner.oneTapMaskedPhone.value.trim();
    return phone.isEmpty ? '本机号码' : phone;
  }

  /// 点击「一键登录」。
  Future<bool> submit() async {
    if (submitting.value) {
      return false;
    }
    if (!_owner.ensureAgreement()) {
      return false;
    }
    if (!_owner._useMock && !await _owner.ensureOneTapReady()) {
      return false;
    }

    submitting.value = true;
    try {
      final session = _owner._useMock
          ? await _owner.mockSession(
              maskedPhone: _owner.oneTapMaskedPhone.value,
            )
          : await _oneTapSession();
      await _owner.saveSession(session);
      if (!_owner._useMock) {
        await _numberAuth.finishLogin(success: true);
      }
      return true;
    } on _OneTapCancelledException {
      return false;
    } on ApiException catch (error) {
      if (_owner._useMock) {
        CustomToast.text(error.userMessage);
      } else {
        await _numberAuth.finishLogin(
          success: false,
          message: error.userMessage,
        );
        _owner.fallbackToPhoneMode();
      }
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('[Auth][OneTap] submit failed', error, stackTrace);
      if (_owner._useMock) {
        CustomToast.text('一键登录失败，请稍后重试');
      } else {
        await _numberAuth.finishLogin(
          success: false,
          message: '一键登录失败，请使用短信验证码登录',
        );
        _owner.fallbackToPhoneMode();
      }
      return false;
    } finally {
      submitting.value = false;
    }
  }

  Future<AuthSession> _oneTapSession() async {
    final tokenResult = await _numberAuth.getLoginToken();
    if (tokenResult.isCancelled) {
      _owner.fallbackToPhoneMode();
      throw const _OneTapCancelledException();
    }
    if (!tokenResult.hasToken) {
      _owner.fallbackToPhoneMode();
      final message = tokenResult.message.trim().isEmpty
          ? '一键登录暂不可用，请使用短信验证码登录'
          : tokenResult.message;
      throw ApiException(type: ApiErrorType.serviceBusy, message: message);
    }

    return AuthAPI.oneClickLogin(
      provider: AliyunNumberAuthService.provider,
      providerToken: tokenResult.token!.trim(),
      inviteCode: _owner.pendingInviteCode,
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw const ApiException(
          type: ApiErrorType.serviceBusy,
          message: '一键登录超时，请使用短信验证码登录',
        );
      },
    );
  }

  void dispose() {}
}
