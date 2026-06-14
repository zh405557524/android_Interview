part of 'index.dart';

final class MockInterviewController extends GetxController {
  /// Current mock interview page state.
  final Rx<ViewState> state = ViewState.success.obs;

  /// Active mock interview session.
  final Rxn<MockSession> session = Rxn<MockSession>();

  /// Text controllers keyed by question id for answer input.
  final Map<String, TextEditingController> answerControllers =
      <String, TextEditingController>{};

  /// Last answer result keyed by question id.
  final RxMap<String, MockAnswerResult> answerResults =
      <String, MockAnswerResult>{}.obs;

  /// Starts a quick mock session using the backend default question pool.
  Future<void> startQuickMock() async {
    state.value = ViewState.loading;
    answerResults.clear();
    _disposeAnswerControllers();
    try {
      session.value = await OfferHunterAPI.createMockSession(
        mode: 'quick',
        questionCount: 5,
      );
      _ensureControllers();
      state.value = ViewState.success;
    } catch (error, stackTrace) {
      CustomToast.error(
        'Mock creation failed',
        error: error,
        stackTrace: stackTrace,
      );
      state.value = ViewState.error;
    }
  }

  /// Submits the answer for one question in the active session.
  Future<void> submitAnswer(MockQuestion question) async {
    final current = session.value;
    if (current == null) {
      return;
    }
    final text = answerControllers[question.questionId]?.text.trim() ?? '';
    if (text.isEmpty) {
      CustomToast.text('Write your answer first');
      return;
    }
    try {
      final result = await OfferHunterAPI.submitMockAnswer(
        sessionId: current.sessionId,
        questionId: question.questionId,
        answerText: text,
      );
      answerResults[question.questionId] = result;
      session.value = await OfferHunterAPI.mockSession(current.sessionId);
      _ensureControllers();
    } catch (error, stackTrace) {
      CustomToast.error(
        'Answer submit failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the editing controller for a question.
  TextEditingController answerController(String questionId) {
    return answerControllers.putIfAbsent(questionId, TextEditingController.new);
  }

  void _ensureControllers() {
    for (final question in session.value?.questions ?? const <MockQuestion>[]) {
      answerController(question.questionId);
    }
  }

  void _disposeAnswerControllers() {
    for (final controller in answerControllers.values) {
      controller.dispose();
    }
    answerControllers.clear();
  }

  @override
  void onClose() {
    _disposeAnswerControllers();
    super.onClose();
  }
}
