part of 'index.dart';

final class HttpService extends GetxService {
  HttpService() : client = Dio(_defaultOptions()) {
    if (client.httpClientAdapter is IOHttpClientAdapter) {
      final adapter = client.httpClientAdapter as IOHttpClientAdapter;
      adapter.createHttpClient = () {
        final httpClient = HttpClient();
        httpClient.connectionTimeout = const Duration(seconds: 30);
        return httpClient;
      };
    }
  }

  static BaseOptions _defaultOptions() {
    return BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status > 0,
      headers: <String, dynamic>{
        AppConstants.appCodeHeader: AppConstants.appCode,
      },
    );
  }

  static HttpService get to => Get.find<HttpService>();

  final Dio client;

  String get baseUrl => client.options.baseUrl;

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;

  void setBaseUrl(String value) {
    client.options.baseUrl = value.trim();
  }

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      client.options.headers.remove('Authorization');
      return;
    }

    client.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<BaseResponse> get(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    bool excludeToken = false,
  }) async {
    return _request(() {
      return client.get<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: _options(options, excludeToken: excludeToken),
        cancelToken: cancelToken,
      );
    }, excludeToken: excludeToken);
  }

  Future<BaseResponse> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool excludeToken = false,
  }) async {
    return _request(() {
      return client.post<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: _options(options, excludeToken: excludeToken),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    }, excludeToken: excludeToken);
  }

  Future<BaseResponse> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    bool excludeToken = false,
  }) async {
    return _request(() {
      return client.delete<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: _options(options, excludeToken: excludeToken),
        cancelToken: cancelToken,
      );
    }, excludeToken: excludeToken);
  }

  Future<BaseResponse> _request(
    Future<Response<Object?>> Function() request, {
    required bool excludeToken,
    bool retryOnUnauthorized = true,
  }) async {
    _syncBaseUrl();
    if (!hasBaseUrl) {
      throw const ApiException(
        type: ApiErrorType.serviceBusy,
        message: '后端地址未配置，请切换 Mock 模式或配置 API Base URL',
      );
    }

    try {
      final hadAuthorizationHeader =
          excludeToken && client.options.headers.containsKey('Authorization');
      final authorizationHeader = client.options.headers['Authorization'];
      if (hadAuthorizationHeader) {
        client.options.headers.remove('Authorization');
      }
      final Response<Object?> response;
      try {
        response = await request();
      } finally {
        if (hadAuthorizationHeader) {
          client.options.headers['Authorization'] = authorizationHeader;
        }
      }
      final result = BaseResponse.fromJson(response.data);
      final statusException = _exceptionFromHttpStatus(
        response.statusCode,
        result,
      );
      if (statusException != null) {
        return _handleApiException(
          statusException,
          request,
          excludeToken: excludeToken,
          retryOnUnauthorized: retryOnUnauthorized,
        );
      }
      if (!result.isSuccess) {
        final exception = ApiException(
          type: _typeFromBusinessCode(result.code),
          message: result.message,
          statusCode: response.statusCode,
        );
        return _handleApiException(
          exception,
          request,
          excludeToken: excludeToken,
          retryOnUnauthorized: retryOnUnauthorized,
        );
      }
      return result;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final exception = _mapDioError(error);
      return _handleApiException(
        exception,
        request,
        excludeToken: excludeToken,
        retryOnUnauthorized: retryOnUnauthorized,
      );
    } catch (_) {
      throw const ApiException(type: ApiErrorType.unknown);
    }
  }

  Options _options(Options? options, {required bool excludeToken}) {
    final headers = <String, dynamic>{
      AppConstants.appCodeHeader: AppConstants.appCode,
      ...?options?.headers,
    };
    if (!excludeToken &&
        Get.isRegistered<UserStore>() &&
        Get.find<UserStore>().isLoggedIn) {
      headers['Authorization'] = 'Bearer ${Get.find<UserStore>().token.value}';
    }
    return (options ?? Options()).copyWith(headers: headers);
  }

  void _syncBaseUrl() {
    if (!Get.isRegistered<ConfigStore>()) {
      return;
    }
    final value = Get.find<ConfigStore>().apiBaseUrl.value.trim();
    if (value != baseUrl) {
      setBaseUrl(value);
    }
  }

  ApiException _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        type: ApiErrorType.serviceBusy,
        message: '网络连接异常，请检查网络',
        statusCode: error.response?.statusCode,
      );
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final businessCode = _responseCode(data);
    final message = _responseMessage(data) ?? error.message;
    final businessType = _typeFromBusinessCode(businessCode);
    final type = switch (statusCode ?? 0) {
      400 => ApiErrorType.validation,
      401 => ApiErrorType.unauthenticated,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.validation,
      402 => ApiErrorType.paymentFailed,
      423 => ApiErrorType.entitlementRequired,
      429 => ApiErrorType.serviceBusy,
      >= 500 => ApiErrorType.serviceBusy,
      _ => ApiErrorType.unknown,
    };
    return ApiException(
      type: businessType == ApiErrorType.unknown ? type : businessType,
      message: message,
      statusCode: statusCode,
    );
  }

  ApiException? _exceptionFromHttpStatus(
    int? statusCode,
    BaseResponse response,
  ) {
    if (statusCode == null || statusCode < 400) {
      return null;
    }
    final businessType = _typeFromBusinessCode(response.code);
    final httpType = switch (statusCode) {
      400 => ApiErrorType.validation,
      401 => ApiErrorType.unauthenticated,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.validation,
      402 => ApiErrorType.paymentFailed,
      423 => ApiErrorType.entitlementRequired,
      429 => ApiErrorType.serviceBusy,
      >= 500 => ApiErrorType.serviceBusy,
      _ => ApiErrorType.unknown,
    };
    return ApiException(
      type: businessType == ApiErrorType.unknown ? httpType : businessType,
      message: response.message,
      statusCode: statusCode,
    );
  }

  Future<BaseResponse> _handleApiException(
    ApiException exception,
    Future<Response<Object?>> Function() request, {
    required bool excludeToken,
    required bool retryOnUnauthorized,
  }) async {
    if (_shouldRefresh(exception, excludeToken, retryOnUnauthorized)) {
      final refreshed = Get.isRegistered<LoginService>()
          ? await Get.find<LoginService>().refreshSession()
          : null;
      if (refreshed != null) {
        return _request(
          request,
          excludeToken: excludeToken,
          retryOnUnauthorized: false,
        );
      }
    }

    if (exception.type == ApiErrorType.unauthenticated && !excludeToken) {
      await _clearSession();
    }
    throw exception;
  }

  bool _shouldRefresh(
    ApiException exception,
    bool excludeToken,
    bool retryOnUnauthorized,
  ) {
    return exception.type == ApiErrorType.unauthenticated &&
        !excludeToken &&
        retryOnUnauthorized;
  }

  ApiErrorType _typeFromBusinessCode(String? code) {
    return switch (code?.trim().toUpperCase()) {
      'BAD_REQUEST' ||
      '-400' ||
      'SMS_CODE_INVALID' ||
      '-1007' ||
      'ONE_CLICK_TOKEN_INVALID' ||
      '-1101' ||
      '400' => ApiErrorType.validation,
      'UNAUTHORIZED' ||
      '-401' ||
      'TOKEN_EXPIRED' ||
      '-1201' ||
      '401' ||
      '9999' => ApiErrorType.unauthenticated,
      'FORBIDDEN' || '-403' || '403' => ApiErrorType.forbidden,
      'NOT_FOUND' || '-404' || '404' => ApiErrorType.notFound,
      'POINTS_NOT_ENOUGH' || '-2001' => ApiErrorType.insufficientPoints,
      'PAYMENT_ORDER_EXPIRED' ||
      '-3001' ||
      'PAYMENT_VERIFY_FAILED' ||
      '-3002' ||
      'PAYMENT_DUPLICATED_CALLBACK' ||
      '-3003' ||
      '402' => ApiErrorType.paymentFailed,
      'ENTITLEMENT_REQUIRED' ||
      '-2003' ||
      '423' => ApiErrorType.entitlementRequired,
      'SMS_TOO_FREQUENT' ||
      '-1001' ||
      'SMS_PHONE_RATE_LIMITED' ||
      '-1002' ||
      'SMS_IP_RATE_LIMITED' ||
      '-1003' ||
      'SMS_DEVICE_RATE_LIMITED' ||
      '-1004' ||
      'SMS_APP_RATE_LIMITED' ||
      '-1005' ||
      'SMS_RISK_CONTROL_UNAVAILABLE' ||
      '-1006' ||
      'SMS_PROVIDER_UNAVAILABLE' ||
      '-1008' ||
      'ONE_CLICK_PROVIDER_UNAVAILABLE' ||
      '-1102' ||
      'GENERATION_PROVIDER_BUSY' ||
      '-5001' ||
      '429' => ApiErrorType.serviceBusy,
      'GENERATION_FAILED' ||
      '-5002' ||
      'GENERATION_TIMEOUT' ||
      '-5003' => ApiErrorType.taskFailed,
      _ => ApiErrorType.unknown,
    };
  }

  String? _responseCode(Object? data) {
    if (data is Map<String, dynamic>) {
      return data['code']?.toString();
    }
    if (data is Map) {
      return data['code']?.toString();
    }
    return null;
  }

  String? _responseMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['msg'] as String? ??
          data['reason'] as String?;
    }
    if (data is Map) {
      return data['message'] as String? ??
          data['msg'] as String? ??
          data['reason'] as String?;
    }
    return null;
  }

  Future<void> _clearSession() async {
    if (Get.isRegistered<LoginService>()) {
      await Get.find<LoginService>().clearSession();
      return;
    }
    if (!Get.isRegistered<UserStore>()) {
      setToken(null);
      return;
    }
    await Get.find<UserStore>().clearSession();
    setToken(null);
  }

  String readableError(Object error) {
    if (error is DioException) {
      return error.message ?? '网络异常，请稍后重试';
    }
    return '请求失败，请稍后重试';
  }
}
