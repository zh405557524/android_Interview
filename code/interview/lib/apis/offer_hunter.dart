part of 'index.dart';

/// Offer Hunter learning, review, and mock interview API adapter.
abstract class OfferHunterAPI {
  /// Loads the first-screen learning overview and featured interview content.
  static Future<OfferHomeOverview> home() async {
    final response = await HttpService.to.get('/api/offer-hunter/home');
    return OfferHomeOverview.fromJson(ApiParser.dataMap(response));
  }

  /// Loads all published knowledge categories for the learning map.
  static Future<List<KnowledgeCategory>> categories() async {
    final response = await HttpService.to.get(
      '/api/offer-hunter/knowledge/categories',
    );
    return ApiParser.dataList(response)
        .whereType<Map>()
        .map(
          (item) => KnowledgeCategory.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Loads one category with its modules and knowledge point list.
  static Future<KnowledgeCategoryDetail> categoryDetail(
    String categoryId,
  ) async {
    final response = await HttpService.to.get(
      '/api/offer-hunter/knowledge/categories/$categoryId',
    );
    return KnowledgeCategoryDetail.fromJson(ApiParser.dataMap(response));
  }

  /// Loads a knowledge point detail, including article blocks and questions.
  static Future<KnowledgePointDetail> pointDetail(String pointId) async {
    final response = await HttpService.to.get(
      '/api/offer-hunter/knowledge/points/$pointId',
    );
    return KnowledgePointDetail.fromJson(ApiParser.dataMap(response));
  }

  /// Marks a knowledge point as completed for the current user.
  static Future<void> completePoint(String pointId) async {
    await HttpService.to.post(
      '/api/offer-hunter/study/progress',
      data: <String, dynamic>{
        'pointId': pointId,
        'status': 'completed',
        'spentSeconds': 60,
      },
    );
  }

  /// Loads today's due review queue for the current user.
  static Future<TodayReview> todayReview() async {
    final response = await HttpService.to.get('/api/offer-hunter/review/today');
    return TodayReview.fromJson(ApiParser.dataMap(response));
  }

  /// Submits one review card feedback result.
  static Future<void> submitReviewFeedback(
    String reviewItemId,
    String result,
  ) async {
    await HttpService.to.post(
      '/api/offer-hunter/review/$reviewItemId/feedback',
      data: <String, dynamic>{'result': result},
    );
  }

  /// Loads wrong-book questions accumulated during mock and review flows.
  static Future<WrongBook> wrongBook() async {
    final response = await HttpService.to.get('/api/offer-hunter/wrong-book');
    return WrongBook.fromJson(ApiParser.dataMap(response));
  }

  /// Creates a mock interview session from selected category or point filters.
  static Future<MockSession> createMockSession({
    String? mode,
    String? categoryId,
    List<String>? pointIds,
    int? questionCount,
  }) async {
    final response = await HttpService.to.post(
      '/api/offer-hunter/mock-sessions',
      data: <String, dynamic>{
        if (mode != null) 'mode': mode,
        if (categoryId != null) 'categoryId': categoryId,
        if (pointIds != null) 'pointIds': pointIds,
        if (questionCount != null) 'questionCount': questionCount,
      },
    );
    return MockSession.fromJson(ApiParser.dataMap(response));
  }

  /// Loads a mock interview session and all contained question states.
  static Future<MockSession> mockSession(String sessionId) async {
    final response = await HttpService.to.get(
      '/api/offer-hunter/mock-sessions/$sessionId',
    );
    return MockSession.fromJson(ApiParser.dataMap(response));
  }

  /// Submits one mock answer and returns the score with the standard answer.
  static Future<MockAnswerResult> submitMockAnswer({
    required String sessionId,
    required String questionId,
    required String answerText,
  }) async {
    final response = await HttpService.to.post(
      '/api/offer-hunter/mock-sessions/$sessionId/answers',
      data: <String, dynamic>{
        'questionId': questionId,
        'answerText': answerText,
      },
    );
    return MockAnswerResult.fromJson(ApiParser.dataMap(response));
  }

  /// Loads the user's Offer Hunter dashboard for the profile tab.
  static Future<ProfileDashboard> profileDashboard() async {
    final response = await HttpService.to.get('/api/offer-hunter/me/dashboard');
    return ProfileDashboard.fromJson(ApiParser.dataMap(response));
  }
}
