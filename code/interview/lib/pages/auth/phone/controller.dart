part of '../index.dart';

/// 手机号 + 短信验证码登录流程。
final class PhoneLoginController {
  PhoneLoginController({required AuthController owner}) : _owner = owner;

  final AuthController _owner;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  /// 是否正在提交短信登录。
  final RxBool submitting = false.obs;

  /// 是否正在请求发送验证码。
  final RxBool sendingCode = false.obs;

  /// 验证码发送冷却剩余秒数；0 表示可再次发送。
  final RxInt secondsLeft = 0.obs;

  /// 手机号是否通过格式校验。
  final RxBool phoneInputValid = false.obs;

  Timer? _timer;

  bool get canSendCode =>
      phoneInputValid.value && secondsLeft.value == 0 && !sendingCode.value;

  void init() {
    _syncPhoneInputValid();
    phoneController.addListener(_syncPhoneInputValid);
  }

  void _syncPhoneInputValid() {
    final valid = AppValidators.isPhone(phoneController.text);
    if (phoneInputValid.value != valid) {
      phoneInputValid.value = valid;
    }
  }

  Future<bool> sendCode() async {
    final phoneError = AppValidators.phoneError(phoneController.text);
    if (phoneError != null) {
      CustomToast.text(phoneError);
      return false;
    }
    if (secondsLeft.value > 0 || sendingCode.value) {
      return false;
    }

    sendingCode.value = true;
    try {
      var cooldownSeconds = 60;
      if (_owner._useMock) {
        await _owner._mock.resolve<bool>(true, mockKey: 'auth.smsCode');
      } else {
        cooldownSeconds = await AuthAPI.sendSmsCode(
          phone: phoneController.text.trim(),
        );
      }
      _startCountdown(cooldownSeconds);
      CustomToast.text('验证码已发送');
      return true;
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
      return false;
    } finally {
      sendingCode.value = false;
    }
  }

  Future<bool> submit() async {
    if (!_owner.ensureAgreement()) {
      return false;
    }
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();
    final phoneError = AppValidators.phoneError(phone);
    if (phoneError != null) {
      CustomToast.text(phoneError);
      return false;
    }
    final codeError = AppValidators.smsCodeError(code);
    if (codeError != null) {
      CustomToast.text(codeError);
      return false;
    }

    submitting.value = true;
    try {
      final params = LoginParams(
        phone: phone,
        code: code,
        inviteCode: _owner.pendingInviteCode,
      );
      final session = _owner._useMock
          ? await _owner.mockSession(maskedPhone: _owner.maskedPhone(phone))
          : await AuthAPI.smsLogin(params);
      await _owner.saveSession(session);
      return true;
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
      return false;
    } finally {
      submitting.value = false;
    }
  }

  void _startCountdown(int cooldownSeconds) {
    _timer?.cancel();
    secondsLeft.value = cooldownSeconds <= 0 ? 60 : cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        timer.cancel();
        return;
      }
      secondsLeft.value -= 1;
    });
  }

  void dispose() {
    _timer?.cancel();
    phoneController.removeListener(_syncPhoneInputValid);
    phoneController.dispose();
    codeController.dispose();
  }
}
