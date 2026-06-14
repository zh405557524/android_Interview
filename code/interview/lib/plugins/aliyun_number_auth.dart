import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../config/index.dart';
import '../utils/index.dart';

enum NumberAuthResultStatus {
  available,
  unavailable,
  token,
  cancelled,
  unsupported,
  error,
}

final class NumberAuthResult {
  const NumberAuthResult({
    required this.status,
    this.code = '',
    this.message = '',
    this.token,
  });

  factory NumberAuthResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const NumberAuthResult(
        status: NumberAuthResultStatus.error,
        code: 'EMPTY_RESPONSE',
        message: '一键登录返回为空',
      );
    }

    final status = switch ((map['status'] ?? '').toString()) {
      'available' => NumberAuthResultStatus.available,
      'unavailable' => NumberAuthResultStatus.unavailable,
      'token' => NumberAuthResultStatus.token,
      'cancelled' => NumberAuthResultStatus.cancelled,
      'unsupported' => NumberAuthResultStatus.unsupported,
      _ => NumberAuthResultStatus.error,
    };
    return NumberAuthResult(
      status: status,
      code: (map['code'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      token: map['token']?.toString(),
    );
  }

  const NumberAuthResult.unsupported()
    : status = NumberAuthResultStatus.unsupported,
      code = 'UNSUPPORTED_PLATFORM',
      message = '当前平台不支持一键登录',
      token = null;

  const NumberAuthResult.unavailable({this.message = '一键登录暂不可用'})
    : status = NumberAuthResultStatus.unavailable,
      code = 'UNAVAILABLE',
      token = null;

  final NumberAuthResultStatus status;
  final String code;
  final String message;
  final String? token;

  bool get isAvailable => status == NumberAuthResultStatus.available;
  bool get hasToken =>
      status == NumberAuthResultStatus.token &&
      (token?.trim().isNotEmpty ?? false);
  bool get isCancelled => status == NumberAuthResultStatus.cancelled;
  bool get shouldFallbackToSms =>
      status == NumberAuthResultStatus.unavailable ||
      status == NumberAuthResultStatus.unsupported ||
      status == NumberAuthResultStatus.cancelled;
}

final class AliyunNumberAuthService extends GetxService {
  AliyunNumberAuthService({
    MethodChannel? channel,
    String? authSdkInfo,
    this.platformOverride,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _explicitAuthSdkInfo = _normalizeAuthSdkInfo(authSdkInfo);

  static const String provider = 'ALIYUN';
  static const String _channelName = 'narrate/aliyun_number_auth';

  final MethodChannel _channel;
  final String? _explicitAuthSdkInfo;
  final TargetPlatform? platformOverride;

  bool _configured = false;

  static String? _normalizeAuthSdkInfo(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  TargetPlatform get _platform => platformOverride ?? defaultTargetPlatform;

  String get _authSdkInfo =>
      _explicitAuthSdkInfo ?? AliyunAuthConfig.forPlatform(_platform);

  bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return _platform == TargetPlatform.iOS ||
        _platform == TargetPlatform.android;
  }

  bool get hasAuthInfo => _authSdkInfo.trim().isNotEmpty;

  static const String _logTag = '[AliyunAuth]';

  void _log(String message) {
    AppLogger.info('$_logTag $message');
  }

  Future<NumberAuthResult> checkAvailability() async {
    _log(
      'checkAvailability platform=${_platform.name} '
      'hasAuthInfo=$hasAuthInfo sdkLen=${_authSdkInfo.trim().length}',
    );
    if (!isSupportedPlatform) {
      _log('不支持的平台 → unsupported');
      return const NumberAuthResult.unsupported();
    }
    if (!hasAuthInfo) {
      _log('密钥为空 → unavailable（检查 AliyunAuthConfig.android）');
      return const NumberAuthResult.unavailable(message: '阿里云号码认证未配置');
    }

    final configured = await configure();
    if (!configured.isAvailable) {
      _log(
        'configure 失败 status=${configured.status.name} '
        'code=${configured.code} message=${configured.message}',
      );
      return configured;
    }
    final env = await _invoke('checkEnv');
    _log(
      'checkEnv status=${env.status.name} code=${env.code} message=${env.message}',
    );
    return env;
  }

  Future<NumberAuthResult> configure() async {
    if (_configured) {
      _log('configure 已缓存，跳过');
      return const NumberAuthResult(
        status: NumberAuthResultStatus.available,
        code: 'OK',
        message: 'SDK 已配置',
      );
    }

    _log('configure 开始 sdkLen=${_authSdkInfo.trim().length}');
    final result = await _invoke('configure', <String, dynamic>{
      'authSdkInfo': _authSdkInfo.trim(),
    });
    _configured = result.isAvailable;
    _log(
      'configure 结束 status=${result.status.name} code=${result.code} '
      'message=${result.message}',
    );
    return result;
  }

  Future<NumberAuthResult> accelerateLoginPage() async {
    if (!isSupportedPlatform || !hasAuthInfo) {
      return const NumberAuthResult.unsupported();
    }
    if (!_configured) {
      final configured = await configure();
      if (!configured.isAvailable) {
        return configured;
      }
    }
    return _invoke('accelerateLoginPage');
  }

  Future<NumberAuthResult> getLoginToken() async {
    if (!isSupportedPlatform) {
      return const NumberAuthResult.unsupported();
    }
    if (!hasAuthInfo) {
      return const NumberAuthResult.unavailable(message: '阿里云号码认证未配置');
    }
    if (!_configured) {
      final configured = await configure();
      if (!configured.isAvailable) {
        return configured;
      }
    }
    return _invoke('getLoginToken');
  }

  Future<void> finishLogin({required bool success, String message = ''}) async {
    if (!isSupportedPlatform) {
      return;
    }
    await _invoke('finishLogin', <String, dynamic>{
      'success': success,
      'message': message,
    });
  }

  Future<void> cancelLogin() async {
    if (!isSupportedPlatform) {
      return;
    }
    await _invoke('cancelLogin');
  }

  Future<NumberAuthResult> _invoke(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final result = await _channel
          .invokeMethod<Object?>(method, arguments)
          .timeout(_timeoutFor(method));
      return NumberAuthResult.fromMap(
        result is Map ? Map<dynamic, dynamic>.from(result) : null,
      );
    } on TimeoutException {
      return NumberAuthResult(
        status: NumberAuthResultStatus.unavailable,
        code: 'TIMEOUT',
        message: method == 'getLoginToken' ? '一键登录超时，请使用短信验证码登录' : '一键登录服务响应超时',
      );
    } on MissingPluginException {
      return const NumberAuthResult.unsupported();
    } on PlatformException catch (error) {
      return NumberAuthResult(
        status: NumberAuthResultStatus.error,
        code: error.code,
        message: error.message ?? '一键登录失败',
      );
    }
  }

  Duration _timeoutFor(String method) {
    return switch (method) {
      'getLoginToken' => const Duration(seconds: 12),
      'finishLogin' || 'cancelLogin' => const Duration(seconds: 4),
      _ => const Duration(seconds: 8),
    };
  }
}
