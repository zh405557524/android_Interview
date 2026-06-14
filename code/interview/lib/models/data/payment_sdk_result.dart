/// 第三方支付 SDK 返回结果。
///
/// 客户端结果只用于判断是否继续查询订单，不作为权益发放依据。
final class PaymentSdkResult {
  const PaymentSdkResult({
    required this.status,
    this.code = '',
    this.message = '',
    this.raw = const <String, dynamic>{},
  });

  /// SDK 侧状态。
  final PaymentSdkResultStatus status;

  /// SDK 原始状态码。
  final String code;

  /// SDK 原始提示。
  final String message;

  /// SDK 原始返回。
  final Map<String, dynamic> raw;

  bool get isSuccess => status == PaymentSdkResultStatus.success;
  bool get isProcessing => status == PaymentSdkResultStatus.processing;
  bool get isCanceled => status == PaymentSdkResultStatus.canceled;
  bool get isFailed => status == PaymentSdkResultStatus.failed;
  bool get shouldQueryOrder =>
      isSuccess || isProcessing || status == PaymentSdkResultStatus.unknown;

  factory PaymentSdkResult.fromAlipayMap(Map<dynamic, dynamic>? map) {
    final raw = <String, dynamic>{
      if (map != null)
        for (final entry in map.entries) '${entry.key}': entry.value,
    };
    final code = '${raw['resultStatus'] ?? raw['status'] ?? ''}'.trim();
    final message = '${raw['memo'] ?? raw['message'] ?? ''}'.trim();
    final status = switch (code) {
      '9000' => PaymentSdkResultStatus.success,
      '8000' => PaymentSdkResultStatus.processing,
      '6001' => PaymentSdkResultStatus.canceled,
      '4000' || '5000' || '6002' => PaymentSdkResultStatus.failed,
      _ => PaymentSdkResultStatus.unknown,
    };
    return PaymentSdkResult(
      status: status,
      code: code,
      message: message,
      raw: raw,
    );
  }
}

enum PaymentSdkResultStatus { success, processing, canceled, failed, unknown }
