part of 'index.dart';

typedef AlipayPayExecutor =
    Future<Map<dynamic, dynamic>?> Function(String orderInfo, AliPayEvn evn);

/// 第三方支付 SDK 网关。
///
/// 只负责调起客户端 SDK；支付是否真正成功由后端订单状态确认。
final class PaymentGatewayService extends GetxService {
  PaymentGatewayService({AlipayPayExecutor? alipayExecutor})
    : _alipayExecutor = alipayExecutor ?? _defaultAlipayExecutor;

  final AlipayPayExecutor _alipayExecutor;

  Future<PaymentSdkResult> pay(PaymentOrder order) async {
    return switch (order.channel) {
      PaymentChannel.alipay => _payAlipay(order),
      PaymentChannel.wechat => throw const ApiException(
        type: ApiErrorType.validation,
        message: '当前仅支持支付宝',
      ),
      PaymentChannel.appleIap => throw const ApiException(
        type: ApiErrorType.validation,
        message: '当前仅支持支付宝',
      ),
    };
  }

  Future<PaymentSdkResult> _payAlipay(PaymentOrder order) async {
    final orderInfo = _normalizeAlipayOrderInfo(order.orderInfo);
    if (orderInfo.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.paymentFailed,
        message: '支付参数为空，请重新下单',
      );
    }
    try {
      final evn = alipayEvnForPaymentEnvironment(PaymentConfig.environment);
      AppLogger.info('[Payment][Gateway] call alipay env=${evn.name}');
      final result = await _alipayExecutor(orderInfo, evn);
      return PaymentSdkResult.fromAlipayMap(result);
    } on MissingPluginException catch (error, stackTrace) {
      AppLogger.error('[Payment][Gateway] 支付宝 SDK 未初始化', error, stackTrace);
      throw const ApiException(
        type: ApiErrorType.paymentFailed,
        message: '支付宝 SDK 未初始化',
      );
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error('[Payment][Gateway] 支付宝调起失败', error, stackTrace);
      throw ApiException(
        type: ApiErrorType.paymentFailed,
        message: error.message ?? '支付宝调起失败',
      );
    }
  }

  static Future<Map<dynamic, dynamic>?> _defaultAlipayExecutor(
    String orderInfo,
    AliPayEvn evn,
  ) {
    return Tobias().pay(orderInfo, evn: evn);
  }
}

AliPayEvn alipayEvnForPaymentEnvironment(PaymentEnvironment environment) {
  return switch (environment) {
    PaymentEnvironment.sandbox => AliPayEvn.sandbox,
    PaymentEnvironment.production => AliPayEvn.online,
  };
}

String _normalizeAlipayOrderInfo(String orderInfo) {
  final raw = orderInfo.trim();
  if (raw.isEmpty || !raw.contains('=')) {
    return raw;
  }
  final parts = raw.split('&');
  if (parts.any((item) => item.trim().isEmpty || !item.contains('='))) {
    return raw;
  }
  return parts
      .map((part) {
        final separator = part.indexOf('=');
        final key = part.substring(0, separator).trim();
        final value = part.substring(separator + 1);
        if (key.isEmpty) {
          return part;
        }
        if (!_shouldEncodeOrderValue(key, value)) {
          return '$key=$value';
        }
        final decoded = _decodeOrderComponent(value);
        return '$key=${Uri.encodeQueryComponent(decoded)}';
      })
      .join('&');
}

bool _shouldEncodeOrderValue(String key, String value) {
  if (value.isEmpty) {
    return false;
  }
  if (_hasMalformedPercentEncoding(value) || RegExp(r'\s').hasMatch(value)) {
    return true;
  }
  if (key == 'sign' &&
      (value.contains('+') || value.contains('/') || value.contains('='))) {
    return true;
  }
  return value.runes.any((rune) {
    if (_isUnreservedQueryRune(rune) || rune == 0x25 || rune == 0x2B) {
      return false;
    }
    return true;
  });
}

bool _hasMalformedPercentEncoding(String value) {
  for (var index = 0; index < value.length; index += 1) {
    if (value.codeUnitAt(index) != 0x25) {
      continue;
    }
    if (index + 2 >= value.length ||
        !_isHex(value.codeUnitAt(index + 1)) ||
        !_isHex(value.codeUnitAt(index + 2))) {
      return true;
    }
    index += 2;
  }
  return false;
}

bool _isHex(int value) {
  return (value >= 0x30 && value <= 0x39) ||
      (value >= 0x41 && value <= 0x46) ||
      (value >= 0x61 && value <= 0x66);
}

bool _isUnreservedQueryRune(int rune) {
  return (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A) ||
      rune == 0x2D ||
      rune == 0x2E ||
      rune == 0x5F ||
      rune == 0x7E;
}

String _decodeOrderComponent(String value) {
  try {
    // `decodeComponent` keeps literal plus signs intact, which matters for
    // RSA signatures. `decodeQueryComponent` would turn `+` into spaces.
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}
