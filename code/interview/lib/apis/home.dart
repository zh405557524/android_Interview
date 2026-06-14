part of 'index.dart';

abstract class HomeAPI {
  /// 获取首页热门案例分类。
  ///
  /// 候选接口：`GET /api/config/home-case-categories`。
  static Future<List<HomeCaseCategory>> fetchCategories() async {
    final response = await HttpService.to.get(
      '/api/config/home-case-categories',
    );
    return ApiParser.dataList(response).map((item) {
      return HomeCaseCategory.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  /// 获取首页热门案例列表。
  ///
  /// 候选接口：`GET /api/config/home-cases`。
  /// [categoryCode] 为后台可维护分类编码；空态和 mock 分支由 HomeController 处理。
  static Future<List<HomeCase>> fetchCases({
    String categoryCode = 'hot',
  }) async {
    final response = await HttpService.to.get(
      '/api/config/home-cases',
      query: <String, dynamic>{'categoryCode': categoryCode},
    );
    return ApiParser.dataList(response).map((item) {
      return HomeCase.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  /// 获取首页案例播放详情。
  ///
  /// 对应接口：`GET /api/config/home-cases/{caseId}`。
  static Future<HomeCase> fetchCaseDetail(String caseId) async {
    final response = await HttpService.to.get('/api/config/home-cases/$caseId');
    return HomeCase.fromJson(ApiParser.dataMap(response));
  }

  /// 记录案例卡片使用次数。
  ///
  /// 该接口只做统计，不返回播放数据；播放页详情请调用 [fetchCaseDetail]。
  static Future<void> useCase(String caseId) async {
    await HttpService.to.post('/api/config/home-cases/$caseId/use');
  }
}
