part of 'index.dart';

final class FeedbackController extends GetxController {
  final TextEditingController contentController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  final Rx<FeedbackType> type = FeedbackType.feature.obs;
  final RxBool submitting = false.obs;

  final List<FeedbackType> types = const <FeedbackType>[
    FeedbackType.feature,
    FeedbackType.bug,
    FeedbackType.payment,
    FeedbackType.other,
  ];

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  void selectType(FeedbackType value) {
    type.value = value;
  }

  Future<void> submit() async {
    final content = contentController.text.trim();
    final contentError = AppValidators.requiredError(content, '请输入反馈内容');
    if (contentError != null) {
      CustomToast.text(contentError);
      return;
    }

    submitting.value = true;
    try {
      final params = FeedbackParams(
        type: type.value,
        content: content,
        contact: contactController.text.trim(),
      );
      if (_useMock) {
        await _mock.resolve<bool>(true, mockKey: 'feedback.submit');
      } else {
        await FeedbackAPI.submit(params);
      }
      contentController.clear();
      contactController.clear();
      CustomToast.text('反馈已提交');
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    contentController.dispose();
    contactController.dispose();
    super.onClose();
  }
}

extension FeedbackTypeLabel on FeedbackType {
  String get label {
    return switch (this) {
      FeedbackType.feature => '功能建议',
      FeedbackType.bug => '问题反馈',
      FeedbackType.payment => '支付问题',
      FeedbackType.other => '其他',
    };
  }
}
