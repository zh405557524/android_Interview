part of 'index.dart';

/// 登录页当前展示的登录方式。
enum AuthLoginMode {
  /// 运营商一键登录（阿里云号码认证）。
  oneTap,

  /// 手机号 + 短信验证码登录。
  phone,
}

/// 登录页总控制器：决定展示一键/短信面板，并协调子流程与协议、会话。
final class AuthController extends GetxController {
  AuthController({this.initialInviteCode}) {
    phone = PhoneLoginController(owner: this);
    oneTap = OneTapLoginController(owner: this);
  }

  static const String pendingInviteCodeKey = 'invite.pendingCode';

  final String? initialInviteCode;

  /// 当前登录面板：一键登录或短信登录。
  final Rx<AuthLoginMode> mode = AuthLoginMode.phone.obs;

  /// 是否已勾选用户协议与隐私政策。
  final RxBool agreementAccepted = false.obs;

  /// 当前环境是否支持一键登录（预检结果；控制默认页与「返回一键登录」）。
  final RxBool oneTapAvailable = false.obs;

  /// 是否正在预检一键登录环境。
  final RxBool checkingOneTap = false.obs;

  /// 一键页展示的脱敏号码；无预取时 UI 显示「本机号码」。
  final RxString oneTapMaskedPhone = ''.obs;

  /// 短信验证码登录子控制器。
  late final PhoneLoginController phone;

  /// 一键登录子控制器（仅负责点击一键登录后的提交流程）。
  late final OneTapLoginController oneTap;

  /// 用户是否主动切到过短信登录；为 true 时预检通过也不自动切回一键页。
  bool _phoneModeSelectedByUser = false;

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  AliyunNumberAuthService get _numberAuth =>
      Get.isRegistered<AliyunNumberAuthService>()
      ? Get.find<AliyunNumberAuthService>()
      : AliyunNumberAuthService();

  /// 当前是否为短信登录面板。
  bool get isPhoneMode => mode.value == AuthLoginMode.phone;

  static const String _oneTapLogTag = '[Auth][OneTap]';

  void _logOneTap(String message) {
    AppLogger.info('$_oneTapLogTag $message');
  }

  @override
  void onInit() {
    super.onInit();
    _cacheInitialInviteCode();
    phone.init();
    _resolveInitialLoginMode();
  }

  String? get pendingInviteCode {
    final value = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>().read<String>(pendingInviteCodeKey)
        : null;
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _cacheInitialInviteCode() {
    final normalized = initialInviteCode?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    if (Get.isRegistered<StorageService>()) {
      unawaited(
        Get.find<StorageService>().write(pendingInviteCodeKey, normalized),
      );
    }
  }

  /// 进入登录页：Mock 直接一键；Real 先短信页，再异步预检是否可切一键。
  void _resolveInitialLoginMode() {
    _logOneTap('进入登录页 platform=${defaultTargetPlatform.name} mock=$_useMock');
    if (_useMock) {
      _logOneTap('Mock 模式 → 直接展示一键登录');
      _applyOneTapAvailable(true, maskedPhone: '138****2026');
      mode.value = AuthLoginMode.oneTap;
      return;
    }

    _logOneTap('Real 模式 → 先展示短信页，开始异步预检');
    _applyOneTapAvailable(false);
    oneTapMaskedPhone.value = '';
    mode.value = AuthLoginMode.phone;
    unawaited(_prepareOneTapAvailability());
  }

  /// 用户点击「切换账号」：固定短信登录。
  void showPhoneMode() {
    _logOneTap('用户切换到短信页');
    _phoneModeSelectedByUser = true;
    mode.value = AuthLoginMode.phone;
  }

  /// 用户点击「返回一键登录」：仅 [oneTapAvailable] 为 true 时切到一键页。
  void showOneTapMode() {
    if (!oneTapAvailable.value) {
      _logOneTap('用户点返回一键，但 oneTapAvailable=false，忽略');
      return;
    }
    _logOneTap('用户点返回一键 → 切换到一键页');
    _phoneModeSelectedByUser = false;
    mode.value = AuthLoginMode.oneTap;
  }

  void toggleAgreement(bool value) {
    agreementAccepted.value = value;
  }

  /// 提交登录前校验协议；未勾选时 toast 并返回 false。
  bool ensureAgreement() {
    final error = AppValidators.agreementError(
      agreementAccepted.value,
      '请先阅读并同意用户协议和隐私政策',
    );
    if (error != null) {
      CustomToast.text(error);
      return false;
    }
    return true;
  }

  /// 一键流程失败或用户取消时，回落到短信登录面板。
  void fallbackToPhoneMode() {
    _logOneTap('回落短信页 mode=phone');
    mode.value = AuthLoginMode.phone;
  }

  /// 预检通过且用户未主动选短信时，自动展示一键登录面板。
  void _showOneTapModeIfAllowed() {
    if (_phoneModeSelectedByUser) {
      _logOneTap('预检通过，但用户已主动选短信，不自动切一键页');
      return;
    }
    _logOneTap('预检通过 → 自动切换到一键页');
    mode.value = AuthLoginMode.oneTap;
  }

  /// 异步预检一键是否可用，并更新 [oneTapAvailable] 与默认 [mode]。
  Future<void> _prepareOneTapAvailability() async {
    _logOneTap('开始预检 checkAvailability');
    checkingOneTap.value = true;
    try {
      final result = await _numberAuth.checkAvailability();
      _logOneTap(_describeNumberAuthResult('预检完成', result));
      final isAvailable = result.isAvailable;
      _applyOneTapAvailable(isAvailable);
      if (isAvailable) {
        unawaited(_numberAuth.accelerateLoginPage());
        _showOneTapModeIfAllowed();
      } else {
        _logOneTap('预检不可用 → 保持/回落短信页 mode=${mode.value.name}');
        fallbackToPhoneMode();
      }
    } catch (error, stackTrace) {
      AppLogger.error('$_oneTapLogTag 预检异常', error);
      AppLogger.error('$_oneTapLogTag $stackTrace');
      _applyOneTapAvailable(false);
      fallbackToPhoneMode();
    } finally {
      checkingOneTap.value = false;
      _logOneTap(
        '预检结束 oneTapAvailable=$oneTapAvailable mode=${mode.value.name}',
      );
    }
  }

  /// 点击一键登录前再次确认环境；不可用时切短信页。
  Future<bool> ensureOneTapReady() async {
    if (oneTapAvailable.value) {
      _logOneTap('提交前复用缓存 oneTapAvailable=true');
      return true;
    }
    _logOneTap('提交前 oneTapAvailable=false，重新 checkAvailability');
    final result = await _numberAuth.checkAvailability();
    _logOneTap(_describeNumberAuthResult('提交前复检', result));
    final isAvailable = result.isAvailable;
    _applyOneTapAvailable(isAvailable);
    if (!isAvailable) {
      fallbackToPhoneMode();
    }
    return isAvailable;
  }

  void _applyOneTapAvailable(bool value, {String? maskedPhone}) {
    oneTapAvailable.value = value;
    if (maskedPhone != null) {
      oneTapMaskedPhone.value = maskedPhone;
    }
    _logOneTap(
      '更新 oneTapAvailable=$value maskedPhone=${oneTapMaskedPhone.value.isEmpty ? "(空)" : oneTapMaskedPhone.value}',
    );
  }

  String _describeNumberAuthResult(String stage, NumberAuthResult result) {
    return '$stage status=${result.status.name} code=${result.code} '
        'message=${result.message}';
  }

  /// 登录成功后写入 [UserStore]、更新 HTTP 鉴权头并提示成功。
  Future<void> saveSession(AuthSession session) async {
    await Get.find<UserStore>().saveSessionFromAuth(session);
    if (Get.isRegistered<StorageService>()) {
      await Get.find<StorageService>().remove(pendingInviteCodeKey);
    }
    Get.find<HttpService>().setToken(session.accessToken);
    CustomToast.success('登录成功');
  }

  Future<AuthSession> mockSession({String maskedPhone = '138****2026'}) {
    return _mock.resolve<AuthSession>(
      AuthSession(
        accessToken: 'mock-token-20260518',
        refreshToken: 'mock-refresh-token-20260518',
        profile: UserProfile(
          id: 'user_mock_001',
          maskedPhone: maskedPhone,
          inviteCode: 'JS2026',
          pointsBalance: 120,
          isVip: false,
          nickname: '漫剧工坊用户',
        ),
      ),
      mockKey: 'auth.login',
    );
  }

  String maskedPhone(String phone) {
    if (phone.length < 7) {
      return phone;
    }
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  @override
  void onClose() {
    phone.dispose();
    oneTap.dispose();
    if (!_useMock) {
      unawaited(_numberAuth.cancelLogin());
    }
    super.onClose();
  }
}

/// 用户在一键授权页主动取消，不视为接口失败。
final class _OneTapCancelledException implements Exception {
  const _OneTapCancelledException();
}
