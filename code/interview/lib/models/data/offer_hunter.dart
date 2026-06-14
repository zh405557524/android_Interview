class UserLearningSummary {
  const UserLearningSummary({
    required this.completedPoints,
    required this.totalPoints,
    required this.todayReviewCount,
    required this.wrongQuestionCount,
    required this.mockSessionCount,
    required this.completionRate,
  });

  final int completedPoints;
  final int totalPoints;
  final int todayReviewCount;
  final int wrongQuestionCount;
  final int mockSessionCount;
  final double completionRate;

  factory UserLearningSummary.fromJson(Map<String, dynamic> json) {
    return UserLearningSummary(
      completedPoints: _int(json['completedPoints']),
      totalPoints: _int(json['totalPoints']),
      todayReviewCount: _int(json['todayReviewCount']),
      wrongQuestionCount: _int(json['wrongQuestionCount']),
      mockSessionCount: _int(json['mockSessionCount']),
      completionRate: _double(json['completionRate']),
    );
  }
}

class HomeQuickAction {
  const HomeQuickAction({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.iconName,
  });

  final String code;
  final String title;
  final String subtitle;
  final String route;
  final String iconName;

  factory HomeQuickAction.fromJson(Map<String, dynamic> json) {
    return HomeQuickAction(
      code: _string(json['code']),
      title: _string(json['title']),
      subtitle: _string(json['subtitle']),
      route: _string(json['route']),
      iconName: _string(json['iconName']),
    );
  }
}

class OfferHomeOverview {
  const OfferHomeOverview({
    required this.appCode,
    required this.summary,
    required this.quickActions,
    required this.categories,
    required this.featuredQuestions,
    required this.reviewPreview,
  });

  final String appCode;
  final UserLearningSummary summary;
  final List<HomeQuickAction> quickActions;
  final List<KnowledgeCategory> categories;
  final List<InterviewQuestion> featuredQuestions;
  final List<ReviewItem> reviewPreview;

  factory OfferHomeOverview.fromJson(Map<String, dynamic> json) {
    return OfferHomeOverview(
      appCode: _string(json['appCode']),
      summary: UserLearningSummary.fromJson(_map(json['summary'])),
      quickActions: _list(json['quickActions'], HomeQuickAction.fromJson),
      categories: _list(json['categories'], KnowledgeCategory.fromJson),
      featuredQuestions: _list(
        json['featuredQuestions'],
        InterviewQuestion.fromJson,
      ),
      reviewPreview: _list(json['reviewPreview'], ReviewItem.fromJson),
    );
  }

  factory OfferHomeOverview.empty() {
    return OfferHomeOverview(
      appCode: '',
      summary: const UserLearningSummary(
        completedPoints: 0,
        totalPoints: 0,
        todayReviewCount: 0,
        wrongQuestionCount: 0,
        mockSessionCount: 0,
        completionRate: 0,
      ),
      quickActions: const <HomeQuickAction>[],
      categories: const <KnowledgeCategory>[],
      featuredQuestions: const <InterviewQuestion>[],
      reviewPreview: const <ReviewItem>[],
    );
  }
}

class KnowledgeCategory {
  const KnowledgeCategory({
    required this.categoryId,
    required this.code,
    required this.title,
    required this.description,
    required this.iconName,
    required this.accentColor,
    required this.totalPoints,
    required this.completedPoints,
    required this.sortOrder,
  });

  final String categoryId;
  final String code;
  final String title;
  final String description;
  final String iconName;
  final String accentColor;
  final int totalPoints;
  final int completedPoints;
  final int sortOrder;

  double get progress {
    if (totalPoints <= 0) {
      return 0;
    }
    return completedPoints / totalPoints;
  }

  factory KnowledgeCategory.fromJson(Map<String, dynamic> json) {
    return KnowledgeCategory(
      categoryId: _string(json['categoryId']),
      code: _string(json['code']),
      title: _string(json['title']),
      description: _string(json['description']),
      iconName: _string(json['iconName']),
      accentColor: _string(json['accentColor']),
      totalPoints: _int(json['totalPoints']),
      completedPoints: _int(json['completedPoints']),
      sortOrder: _int(json['sortOrder']),
    );
  }
}

class KnowledgeCategoryDetail {
  const KnowledgeCategoryDetail({
    required this.category,
    required this.modules,
  });

  final KnowledgeCategory category;
  final List<KnowledgeModule> modules;

  factory KnowledgeCategoryDetail.fromJson(Map<String, dynamic> json) {
    return KnowledgeCategoryDetail(
      category: KnowledgeCategory.fromJson(_map(json['category'])),
      modules: _list(json['modules'], KnowledgeModule.fromJson),
    );
  }
}

class KnowledgeModule {
  const KnowledgeModule({
    required this.moduleId,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.sortOrder,
    required this.points,
  });

  final String moduleId;
  final String categoryId;
  final String title;
  final String subtitle;
  final int sortOrder;
  final List<KnowledgePointItem> points;

  factory KnowledgeModule.fromJson(Map<String, dynamic> json) {
    return KnowledgeModule(
      moduleId: _string(json['moduleId']),
      categoryId: _string(json['categoryId']),
      title: _string(json['title']),
      subtitle: _string(json['subtitle']),
      sortOrder: _int(json['sortOrder']),
      points: _list(json['points'], KnowledgePointItem.fromJson),
    );
  }
}

class KnowledgePointItem {
  const KnowledgePointItem({
    required this.pointId,
    required this.categoryId,
    required this.moduleId,
    required this.title,
    required this.summary,
    required this.tags,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.completed,
    required this.questionCount,
    required this.sortOrder,
  });

  final String pointId;
  final String categoryId;
  final String moduleId;
  final String title;
  final String summary;
  final List<String> tags;
  final String difficulty;
  final int estimatedMinutes;
  final bool completed;
  final int questionCount;
  final int sortOrder;

  factory KnowledgePointItem.fromJson(Map<String, dynamic> json) {
    return KnowledgePointItem(
      pointId: _string(json['pointId']),
      categoryId: _string(json['categoryId']),
      moduleId: _string(json['moduleId']),
      title: _string(json['title']),
      summary: _string(json['summary']),
      tags: _stringList(json['tags']),
      difficulty: _string(json['difficulty']),
      estimatedMinutes: _int(json['estimatedMinutes']),
      completed: json['completed'] == true,
      questionCount: _int(json['questionCount']),
      sortOrder: _int(json['sortOrder']),
    );
  }
}

class KnowledgeBlock {
  const KnowledgeBlock({
    required this.type,
    required this.title,
    required this.content,
  });

  final String type;
  final String title;
  final String content;

  factory KnowledgeBlock.fromJson(Map<String, dynamic> json) {
    return KnowledgeBlock(
      type: _string(json['type']),
      title: _string(json['title']),
      content: _string(json['content']),
    );
  }
}

class KnowledgePointDetail {
  const KnowledgePointDetail({
    required this.pointId,
    required this.categoryId,
    required this.moduleId,
    required this.title,
    required this.summary,
    required this.tags,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.completed,
    required this.blocks,
    required this.questions,
  });

  final String pointId;
  final String categoryId;
  final String moduleId;
  final String title;
  final String summary;
  final List<String> tags;
  final String difficulty;
  final int estimatedMinutes;
  final bool completed;
  final List<KnowledgeBlock> blocks;
  final List<InterviewQuestion> questions;

  factory KnowledgePointDetail.fromJson(Map<String, dynamic> json) {
    return KnowledgePointDetail(
      pointId: _string(json['pointId']),
      categoryId: _string(json['categoryId']),
      moduleId: _string(json['moduleId']),
      title: _string(json['title']),
      summary: _string(json['summary']),
      tags: _stringList(json['tags']),
      difficulty: _string(json['difficulty']),
      estimatedMinutes: _int(json['estimatedMinutes']),
      completed: json['completed'] == true,
      blocks: _list(json['blocks'], KnowledgeBlock.fromJson),
      questions: _list(json['questions'], InterviewQuestion.fromJson),
    );
  }
}

class InterviewQuestion {
  const InterviewQuestion({
    required this.questionId,
    required this.categoryId,
    required this.pointId,
    required this.type,
    required this.title,
    required this.prompt,
    required this.answer,
    required this.tags,
    required this.difficulty,
    required this.frequency,
    required this.sortOrder,
  });

  final String questionId;
  final String categoryId;
  final String pointId;
  final String type;
  final String title;
  final String prompt;
  final String answer;
  final List<String> tags;
  final String difficulty;
  final String frequency;
  final int sortOrder;

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      questionId: _string(json['questionId']),
      categoryId: _string(json['categoryId']),
      pointId: _string(json['pointId']),
      type: _string(json['type']),
      title: _string(json['title']),
      prompt: _string(json['prompt']),
      answer: _string(json['answer']),
      tags: _stringList(json['tags']),
      difficulty: _string(json['difficulty']),
      frequency: _string(json['frequency']),
      sortOrder: _int(json['sortOrder']),
    );
  }
}

class TodayReview {
  const TodayReview({
    required this.dueCount,
    required this.wrongQuestionCount,
    required this.items,
  });

  final int dueCount;
  final int wrongQuestionCount;
  final List<ReviewItem> items;

  factory TodayReview.fromJson(Map<String, dynamic> json) {
    return TodayReview(
      dueCount: _int(json['dueCount']),
      wrongQuestionCount: _int(json['wrongQuestionCount']),
      items: _list(json['items'], ReviewItem.fromJson),
    );
  }
}

class ReviewItem {
  const ReviewItem({
    required this.reviewItemId,
    required this.pointId,
    required this.questionId,
    required this.title,
    required this.prompt,
    required this.answer,
    required this.reviewType,
    required this.repeatCount,
    required this.dueAt,
  });

  final String reviewItemId;
  final String pointId;
  final String questionId;
  final String title;
  final String prompt;
  final String answer;
  final String reviewType;
  final int repeatCount;
  final DateTime? dueAt;

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      reviewItemId: _string(json['reviewItemId']),
      pointId: _string(json['pointId']),
      questionId: _string(json['questionId']),
      title: _string(json['title']),
      prompt: _string(json['prompt']),
      answer: _string(json['answer']),
      reviewType: _string(json['reviewType']),
      repeatCount: _int(json['repeatCount']),
      dueAt: _date(json['dueAt']),
    );
  }
}

class WrongBook {
  const WrongBook({required this.total, required this.questions});

  final int total;
  final List<InterviewQuestion> questions;

  factory WrongBook.fromJson(Map<String, dynamic> json) {
    return WrongBook(
      total: _int(json['total']),
      questions: _list(json['questions'], InterviewQuestion.fromJson),
    );
  }
}

class MockSession {
  const MockSession({
    required this.sessionId,
    required this.mode,
    required this.status,
    required this.answeredCount,
    required this.totalCount,
    required this.score,
    required this.createdAt,
    required this.completedAt,
    required this.questions,
  });

  final String sessionId;
  final String mode;
  final String status;
  final int answeredCount;
  final int totalCount;
  final int score;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final List<MockQuestion> questions;

  factory MockSession.fromJson(Map<String, dynamic> json) {
    return MockSession(
      sessionId: _string(json['sessionId']),
      mode: _string(json['mode']),
      status: _string(json['status']),
      answeredCount: _int(json['answeredCount']),
      totalCount: _int(json['totalCount']),
      score: _int(json['score']),
      createdAt: _date(json['createdAt']),
      completedAt: _date(json['completedAt']),
      questions: _list(json['questions'], MockQuestion.fromJson),
    );
  }
}

class MockQuestion {
  const MockQuestion({
    required this.questionId,
    required this.title,
    required this.prompt,
    required this.tags,
    required this.difficulty,
    required this.frequency,
    required this.answered,
    required this.score,
  });

  final String questionId;
  final String title;
  final String prompt;
  final List<String> tags;
  final String difficulty;
  final String frequency;
  final bool answered;
  final int? score;

  factory MockQuestion.fromJson(Map<String, dynamic> json) {
    return MockQuestion(
      questionId: _string(json['questionId']),
      title: _string(json['title']),
      prompt: _string(json['prompt']),
      tags: _stringList(json['tags']),
      difficulty: _string(json['difficulty']),
      frequency: _string(json['frequency']),
      answered: json['answered'] == true,
      score: (json['score'] as num?)?.toInt(),
    );
  }
}

class MockAnswerResult {
  const MockAnswerResult({
    required this.sessionId,
    required this.questionId,
    required this.score,
    required this.passed,
    required this.feedback,
    required this.standardAnswer,
    required this.answeredCount,
    required this.totalCount,
    required this.sessionStatus,
  });

  final String sessionId;
  final String questionId;
  final int score;
  final bool passed;
  final String feedback;
  final String standardAnswer;
  final int answeredCount;
  final int totalCount;
  final String sessionStatus;

  factory MockAnswerResult.fromJson(Map<String, dynamic> json) {
    return MockAnswerResult(
      sessionId: _string(json['sessionId']),
      questionId: _string(json['questionId']),
      score: _int(json['score']),
      passed: json['passed'] == true,
      feedback: _string(json['feedback']),
      standardAnswer: _string(json['standardAnswer']),
      answeredCount: _int(json['answeredCount']),
      totalCount: _int(json['totalCount']),
      sessionStatus: _string(json['sessionStatus']),
    );
  }
}

class ProfileDashboard {
  const ProfileDashboard({
    required this.summary,
    required this.streakDays,
    required this.totalStudyMinutes,
    required this.achievements,
    required this.recentMockSessions,
  });

  final UserLearningSummary summary;
  final int streakDays;
  final int totalStudyMinutes;
  final List<Achievement> achievements;
  final List<MockSession> recentMockSessions;

  factory ProfileDashboard.fromJson(Map<String, dynamic> json) {
    return ProfileDashboard(
      summary: UserLearningSummary.fromJson(_map(json['summary'])),
      streakDays: _int(json['streakDays']),
      totalStudyMinutes: _int(json['totalStudyMinutes']),
      achievements: _list(json['achievements'], Achievement.fromJson),
      recentMockSessions: _list(
        json['recentMockSessions'],
        MockSession.fromJson,
      ),
    );
  }
}

class Achievement {
  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.unlockedAt,
  });

  final String code;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      code: _string(json['code']),
      title: _string(json['title']),
      description: _string(json['description']),
      unlocked: json['unlocked'] == true,
      unlockedAt: _date(json['unlockedAt']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<T> _list<T>(
  Object? value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) {
    return <T>[];
  }
  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return <String>[];
  }
  return value.map((item) => item.toString()).toList();
}

String _string(Object? value) => value?.toString() ?? '';

int _int(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
