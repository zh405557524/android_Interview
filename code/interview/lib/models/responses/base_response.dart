final class BaseResponse {
  const BaseResponse({this.code, this.message, this.data});

  factory BaseResponse.fromJson(Object? json) {
    if (json is Map<String, dynamic>) {
      final hasEnvelope =
          json.containsKey('code') ||
          json.containsKey('msg') ||
          json.containsKey('message') ||
          json.containsKey('data');
      if (hasEnvelope) {
        return BaseResponse(
          code: json['code']?.toString(),
          message: (json['msg'] ?? json['message'])?.toString(),
          data: json['data'],
        );
      }
    }
    if (json is Map) {
      final hasEnvelope =
          json.containsKey('code') ||
          json.containsKey('msg') ||
          json.containsKey('message') ||
          json.containsKey('data');
      if (hasEnvelope) {
        return BaseResponse(
          code: json['code']?.toString(),
          message: (json['msg'] ?? json['message'])?.toString(),
          data: json['data'],
        );
      }
    }
    return BaseResponse(data: json);
  }

  final String? code;
  final String? message;
  final Object? data;

  bool get isSuccess {
    final raw = code?.trim();
    if (raw == null || raw.isEmpty) {
      return true;
    }

    final normalizedCode = raw.toUpperCase();
    if (normalizedCode == 'OK' || normalizedCode == '200') {
      return true;
    }

    final numericCode = int.tryParse(raw);
    if (numericCode != null) {
      // 兼容旧接口成功码 1，以及当前后端统一成功码 200。
      return numericCode == 1 || numericCode == 200;
    }

    return false;
  }
}
