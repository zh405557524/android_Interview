part of 'index.dart';

abstract class AuthAPI {
  /// 运营商一键登录。
  ///
  /// 候选接口：`POST /api/auth/one-click-login`。
  /// 返回登录 token 和用户资料；真实运营商 SDK 未接入前可传后端 mock provider。
  static Future<AuthSession> oneClickLogin({
    required String provider,
    required String providerToken,
    String? inviteCode,
  }) async {
    final response = await HttpService.to.post(
      '/api/auth/one-click-login',
      data: <String, dynamic>{
        'provider': provider,
        'providerToken': providerToken,
        if (inviteCode?.trim().isNotEmpty == true)
          'inviteCode': inviteCode!.trim(),
      },
      excludeToken: true,
    );
    return AuthSession.fromJson(ApiParser.dataMap(response));
  }

  /// 发送短信验证码。
  ///
  /// 候选接口：`POST /api/auth/sms/send`。
  /// 只负责真实请求；发送按钮倒计时和 mock 分支由登录 Controller 处理。
  static Future<int> sendSmsCode({required String phone}) async {
    final deviceId = await _deviceId();
    final response = await HttpService.to.post(
      '/api/auth/sms/send',
      data: <String, dynamic>{'phone': phone},
      options: Options(
        headers: <String, dynamic>{AppConstants.deviceIdHeader: deviceId},
      ),
      excludeToken: true,
    );
    final data = ApiParser.dataMap(response);
    return (data['cooldownSeconds'] as num?)?.toInt() ?? 60;
  }

  /// 短信验证码登录。
  ///
  /// 候选接口：`POST /api/auth/sms/login`。
  /// 返回登录 token 和用户资料；表单校验由登录 Controller 处理。
  static Future<AuthSession> smsLogin(LoginParams params) async {
    final response = await HttpService.to.post(
      '/api/auth/sms/login',
      data: params.toJson(),
      excludeToken: true,
    );
    return AuthSession.fromJson(ApiParser.dataMap(response));
  }

  /// 刷新登录令牌。
  ///
  /// 候选接口：`POST /api/auth/refresh`。
  /// accessToken 过期后由网络层调用；该请求不携带旧 accessToken，
  /// 成功后返回轮换后的 accessToken、refreshToken 和用户资料。
  static Future<AuthSession> refreshToken(String refreshToken) async {
    final response = await HttpService.to.post(
      '/api/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken},
      excludeToken: true,
    );
    return AuthSession.fromJson(ApiParser.dataMap(response));
  }

  static Future<String> _deviceId() async {
    const storageKey = 'auth.deviceId';
    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    final cached = storage?.read<String>(storageKey)?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final generated = 'offer-hunter-${DateTime.now().microsecondsSinceEpoch}';
    await storage?.write(storageKey, generated);
    return generated;
  }
}
