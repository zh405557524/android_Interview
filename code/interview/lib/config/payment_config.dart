part of 'index.dart';

/// 支付环境。
enum PaymentEnvironment {
  /// 正式环境：正式包必须使用该环境，并配套后端正式 appId、密钥和网关。
  production,

  /// 沙箱环境：仅用于联调，需配套后端沙箱 appId、密钥、网关和支付宝沙箱钱包。
  sandbox,
}

/// 支付相关配置。
abstract final class PaymentConfig {
  /// 当前支付宝支付环境。
  ///
  /// 联调阶段默认使用 [PaymentEnvironment.sandbox]；正式发包前必须改为
  /// [PaymentEnvironment.production]，避免线上包误连沙箱支付。
  static const PaymentEnvironment environment = PaymentEnvironment.sandbox;

  /// 是否使用支付宝沙箱环境，用于支付 SDK 调起和调试日志。
  static bool get isSandbox => environment == PaymentEnvironment.sandbox;

  /// 是否使用支付宝正式环境，用于发版前检查和调试日志。
  static bool get isProduction => environment == PaymentEnvironment.production;
}
