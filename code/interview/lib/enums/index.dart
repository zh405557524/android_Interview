part 'view_state.dart';

enum ApiErrorType {
  unauthenticated,
  forbidden,
  validation,
  insufficientPoints,
  entitlementRequired,
  notFound,
  taskFailed,
  paymentFailed,
  serviceBusy,
  unknown,
}

extension ApiErrorTypeMessage on ApiErrorType {
  String get fallbackMessage {
    return switch (this) {
      ApiErrorType.unauthenticated => '请先登录',
      ApiErrorType.forbidden => '暂无操作权限',
      ApiErrorType.validation => '参数有误，请检查后重试',
      ApiErrorType.insufficientPoints => '积分不足',
      ApiErrorType.entitlementRequired => '当前权益不足',
      ApiErrorType.notFound => '内容不存在或已失效',
      ApiErrorType.taskFailed => '任务处理失败',
      ApiErrorType.paymentFailed => '支付失败，请稍后重试',
      ApiErrorType.serviceBusy => '服务繁忙，请稍后重试',
      ApiErrorType.unknown => '请求失败，请稍后重试',
    };
  }
}

enum CreationMode { narration, trimming }

enum FeedbackType { feature, bug, payment, other }

enum InviteRewardStatus { pending, granted, invalid }

enum MaterialStatus { ready, processing, failed }

enum QuickGenerationBatchStatus {
  uploading,
  uploaded,
  analyzing,
  generating,
  succeeded,
  failed,
  canceled,
  expired,
}

enum PaymentChannel { wechat, alipay, appleIap }

enum PaymentOrderStatus { pending, paid, failed, canceled }

enum PaymentPurpose { membership, points }

enum PointDirection { income, expense, frozen, refund }

/// 作品类型。
///
/// 这里直接使用百度智能集锦 project.type 语义，避免前端分类、后端作品类型和
/// 百度项目类型之间出现多套枚举。`all` 只用于作品列表筛选，不会提交给后端。
enum WorkType { all, shortSeries, movie, tvSeries }

extension WorkTypeLabel on WorkType {
  /// 用户侧展示文案。
  String get label {
    return switch (this) {
      WorkType.all => '全部',
      WorkType.shortSeries => '短剧',
      WorkType.movie => '电影',
      WorkType.tvSeries => '电视剧',
    };
  }

  /// 提交给后端的筛选或创建参数，保持与百度 project.type 一致。
  String? get apiValue {
    return switch (this) {
      WorkType.all => null,
      WorkType.shortSeries => 'ShortSeries',
      WorkType.movie => 'Movie',
      WorkType.tvSeries => 'TVSeries',
    };
  }

  /// 当前作品类型允许添加的视频时长范围，单位秒。
  ///
  /// 60 分钟以上按电影处理；电视剧仅接收 10 到 80 分钟之间的视频。
  bool acceptsDuration(int seconds) {
    return switch (this) {
      WorkType.shortSeries => seconds >= 10 && seconds <= 20 * 60,
      WorkType.movie => seconds >= 60 * 60,
      WorkType.tvSeries => seconds >= 10 * 60 && seconds <= 80 * 60,
      WorkType.all => seconds >= 10,
    };
  }

  /// 当前类型的视频时长规则提示。
  String get durationRuleText {
    return switch (this) {
      WorkType.shortSeries => '10秒到20分钟',
      WorkType.movie => '60分钟及以上',
      WorkType.tvSeries => '10到80分钟',
      WorkType.all => '10秒及以上',
    };
  }
}

enum WorkStatus { draft, queued, generating, succeeded, failed, expired }
