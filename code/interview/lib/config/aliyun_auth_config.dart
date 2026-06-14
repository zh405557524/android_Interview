part of 'index.dart';

/// 阿里云号码认证密钥配置。
abstract final class AliyunAuthConfig {
  /// iOS 应用密钥串。
  static const String ios =
      'u53zIQB/WKGTBJ10p5Zu3nwBRoIbkw2noijRzty3+NUoAAIRVg9FoDXLzXDVzcXF+OMKpVp3aY39r4f8z8CtSMqQYSxp316dXd4Pi+EILTsivtK7QoObIZgHFXtkxcfRzNqErK2a4iqavvPPvJiJ0csWXjiZz3F56v2DEgAMfyQgw6XiGHiHEpcboqjUSMOG1H9KWR4i+6n1oKoAe+DO8WeXpypdYwYCDLKvsHoOjjxHiDXjUNMr2ui3/cXp1aao';

  /// Android 应用密钥串。
  static const String android =
      'aei903MZndOyTAqVQlHN7OCdVFbQ2Sgto8XLT+mBw99lPXiS9y+wLx9TmEWycn0Qx3oyR2UKzAL+LbR4U7+1IBnwo+Dl391zNl1Ll9CUhZxyF8c7oz7La+1GlhajmpijRcuKq+FnXsePNgcMhxUw16AgGiojdKtpuxlah+ppLg/gDW5g6nCNEb8xDr4fmJIG1UG47IrqcSDSoPl5h1ooIv/KgHrYyRK4bJGC56NdLTCrvPzwNFo57RmfywimUEFwDEyC74JCEzl+t+9XDIEs5tNRBYYrAvTDc7PIJNPqsmw=';

  static String forPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.iOS => ios,
      TargetPlatform.android => android,
      _ => '',
    };
  }
}
