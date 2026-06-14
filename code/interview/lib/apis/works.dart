part of 'index.dart';

abstract class WorksAPI {
  /// 获取作品列表分页。
  ///
  /// 候选接口：`GET /api/works`。
  /// 支持按百度作品类型筛选；列表空态和刷新逻辑由 WorksController 处理。
  static Future<PageResult<Work>> fetchWorks({
    WorkType workType = WorkType.all,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await HttpService.to.get(
      '/api/works',
      query: <String, dynamic>{
        if (workType.apiValue != null) 'workType': workType.apiValue,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return ApiParser.pageResult<Work>(response, Work.fromJson);
  }

  /// 获取作品详情。
  ///
  /// 候选接口：`GET /api/works/{id}`。
  /// 返回视频地址、生成参数和过期信息，详情页会用 `video_player` 播放视频。
  static Future<WorkDetail> detail(String id) async {
    final response = await HttpService.to.get('/api/works/$id');
    return WorkDetail.fromJson(ApiParser.dataMap(response));
  }

  /// 获取作品下载地址。
  ///
  /// 候选接口：`POST /api/works/{id}/download-url`。
  /// 返回临时下载地址；作品详情页会用独立下载服务保存到系统相册。
  static Future<String> downloadUrl(String id, {String? variantId}) async {
    final normalizedVariantId = variantId?.trim();
    final response = await HttpService.to.post(
      '/api/works/$id/download-url',
      query: normalizedVariantId == null || normalizedVariantId.isEmpty
          ? null
          : <String, dynamic>{'variantId': normalizedVariantId},
    );
    return '${ApiParser.dataMap(response)['downloadUrl'] ?? ''}';
  }

  /// 批量隐藏作品。
  ///
  /// 候选接口：`POST /api/works/disable`。
  /// 业务上用户看到的是“删除”，但后端只做隐藏/下架，不执行物理删除。
  static Future<void> hideWorks(List<String> ids) async {
    await HttpService.to.post(
      '/api/works/disable',
      data: <String, dynamic>{'ids': ids},
    );
  }
}
