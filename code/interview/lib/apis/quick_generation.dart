part of 'index.dart';

abstract class QuickGenerationAPI {
  /// 创建快速批量生成批次。
  ///
  /// 接口路径：`POST /api/generation/quick-batches`。
  /// 流程节点：步骤2：创建快速批次；
  /// 步骤3：后端为每个视频创建本地媒资并申请百度上传凭证。
  /// 调用时机：用户确认积分消耗后、真正上传视频前。mock/real 分支由 Controller 负责。
  static Future<QuickGenerationBatch> createBatch({
    required String title,
    required List<QuickGenerationFile> files,
    required String style,
    required String voice,
    required WorkType workType,
    String? presetId,
    bool diversifiedVersionsEnabled = false,
    int? targetDurationSeconds,
    String? idempotencyKey,
  }) async {
    final response = await HttpService.to.post(
      '/api/generation/quick-batches',
      data: <String, dynamic>{
        'title': title,
        'files': files.map((item) => item.toJson()).toList(),
        'style': style,
        'voice': voice,
        'workType': workType.apiValue,
        'presetId': presetId?.isNotEmpty == true ? presetId : null,
        'diversifiedVersionsEnabled': diversifiedVersionsEnabled,
        'targetDurationSeconds': targetDurationSeconds,
      },
      options: idempotencyKey == null || idempotencyKey.trim().isEmpty
          ? null
          : Options(
              headers: <String, dynamic>{'Idempotency-Key': idempotencyKey},
            ),
    );
    return QuickGenerationBatch.fromJson(ApiParser.dataMap(response));
  }

  /// 上报单个视频已完成上传。
  ///
  /// 接口路径：`POST /api/generation/quick-batches/{batchId}/media/{assetId}/upload-complete`。
  /// 流程节点：步骤5：前端逐个上报 upload-complete；
  /// 步骤6：后端确认全部上传完成并提交百度智能集锦任务。
  /// 调用时机：对应视频完成步骤4“前端将视频文件直传到 uploadUrl”后；
  /// 全部视频完成后后端会自动提交生成。
  static Future<QuickGenerationBatch> completeUpload({
    required String batchId,
    required String assetId,
  }) async {
    final response = await HttpService.to.post(
      '/api/generation/quick-batches/$batchId/media/$assetId/upload-complete',
    );
    return QuickGenerationBatch.fromJson(ApiParser.dataMap(response));
  }

  /// 查询快速批量生成批次状态。
  ///
  /// 接口路径：`GET /api/generation/quick-batches/{batchId}`。
  /// 流程节点：步骤6 后的项目/作品状态轮询。
  /// 调用时机：上传完成后或作品列表刷新前，用于获取本地作品 id 和生成状态。
  static Future<QuickGenerationBatch> detail(String batchId) async {
    final response = await HttpService.to.get(
      '/api/generation/quick-batches/$batchId',
    );
    return QuickGenerationBatch.fromJson(ApiParser.dataMap(response));
  }

  /// 上传快速批次封面。
  ///
  /// 封面来自第一个本地视频的第一帧，后端会绑定到首个媒资，并作为生成中作品的占位封面。
  static Future<QuickGenerationBatch> uploadCover({
    required String batchId,
    required File file,
    required void Function(int sent, int total) onSendProgress,
  }) async {
    final response = await HttpService.to.post(
      '/api/generation/quick-batches/$batchId/cover',
      data: FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'quick_batch_${batchId}_cover.jpg',
        ),
      }),
      options: Options(contentType: Headers.multipartFormDataContentType),
      onSendProgress: onSendProgress,
    );
    return QuickGenerationBatch.fromJson(ApiParser.dataMap(response));
  }

  /// 将本地视频二进制直传到 Provider 返回的上传地址。
  ///
  /// 百度 VOD 返回的是预签名 URL，PUT 阶段必须尽量原样使用该 URL；
  /// 不能带业务接口的 Authorization/x-app-code，也不能重新组装 query。
  static Future<void> uploadFile({
    required String uploadUrl,
    required File file,
    required Map<String, String> headers,
    required void Function(int sent, int total) onSendProgress,
  }) async {
    final length = await file.length();
    final client = HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 30)
      ..userAgent = null;

    try {
      final uri = _uploadUri(uploadUrl);
      final request = await client.putUrl(uri);
      request
        ..followRedirects = false
        ..maxRedirects = 0
        ..persistentConnection = false
        ..contentLength = length;
      _setUploadHeaders(request, headers);

      var sent = 0;
      final progressStream = file.openRead().transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            sink.add(chunk);
            onSendProgress(sent, length);
          },
        ),
      );
      await request.addStream(progressStream);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          type: ApiErrorType.serviceBusy,
          statusCode: response.statusCode,
          message: _baiduUploadErrorMessage(response, body),
        );
      }
      if (length == 0) {
        onSendProgress(0, 0);
      }
    } on ApiException {
      rethrow;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: '视频上传地址无效：${error.message}',
      );
    } on SocketException catch (error) {
      throw ApiException(
        type: ApiErrorType.serviceBusy,
        message: '视频 PUT 到百度失败：${error.message}',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Uri _uploadUri(String uploadUrl) {
    final uri = Uri.parse(uploadUrl);
    if (!uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException('缺少协议或域名');
    }
    return uri;
  }

  static void _setUploadHeaders(
    HttpClientRequest request,
    Map<String, String> headers,
  ) {
    var hasContentType = false;
    headers.forEach((key, value) {
      final normalizedKey = key.trim();
      final normalizedValue = value.trim();
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
        return;
      }
      final lowerKey = normalizedKey.toLowerCase();
      if (lowerKey == HttpHeaders.authorizationHeader ||
          lowerKey == AppConstants.appCodeHeader.toLowerCase() ||
          lowerKey == HttpHeaders.contentLengthHeader) {
        return;
      }
      if (lowerKey == HttpHeaders.contentTypeHeader) {
        hasContentType = true;
      }
      request.headers.set(normalizedKey, normalizedValue);
    });
    if (!hasContentType) {
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/octet-stream',
      );
    }
  }

  static String _baiduUploadErrorMessage(
    HttpClientResponse response,
    String body,
  ) {
    final code =
        _baiduErrorField(body, 'Code') ?? _baiduJsonField(body, 'code');
    final message =
        _baiduErrorField(body, 'Message') ?? _baiduJsonField(body, 'message');
    final requestId =
        response.headers.value('x-bce-request-id') ??
        _baiduErrorField(body, 'RequestId') ??
        _baiduJsonField(body, 'requestId');
    final debugId =
        response.headers.value('x-bce-debug-id') ??
        _baiduErrorField(body, 'DebugId') ??
        _baiduJsonField(body, 'debugId');

    final details = <String>[
      if (code != null && code.isNotEmpty) code,
      if (message != null && message.isNotEmpty) message,
      if (requestId != null && requestId.isNotEmpty) 'requestId=$requestId',
      if (debugId != null && debugId.isNotEmpty) 'debugId=$debugId',
    ];
    if (details.isEmpty && body.trim().isNotEmpty) {
      details.add(_trimUploadErrorBody(body));
    }
    final suffix = details.isEmpty ? '' : ' ${details.join('；')}';
    return '视频 PUT 到百度失败：${response.statusCode}$suffix';
  }

  static String? _baiduErrorField(String body, String fieldName) {
    final match = RegExp(
      '<$fieldName>([\\s\\S]*?)</$fieldName>',
      caseSensitive: false,
    ).firstMatch(body);
    return match == null ? null : _decodeXmlText(match.group(1) ?? '').trim();
  }

  static String? _baiduJsonField(String body, String fieldName) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded[fieldName]?.toString().trim();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String _decodeXmlText(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  static String _trimUploadErrorBody(String body) {
    final normalized = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 180) {
      return normalized;
    }
    return '${normalized.substring(0, 180)}...';
  }
}
