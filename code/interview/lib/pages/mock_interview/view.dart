part of 'index.dart';

class MockInterviewPage extends StatelessWidget {
  const MockInterviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MockInterviewController>()
        ? Get.find<MockInterviewController>()
        : Get.put(MockInterviewController());

    return CustomScaffold(
      appBar: AppBar(title: const Text('Mock interview')),
      body: Obx(
        () => AppStateBuilder(
          state: controller.state.value,
          onRetry: controller.startQuickMock,
          builder: (_) {
            final session = controller.session.value;
            if (session == null) {
              return _MockStart(controller: controller);
            }
            return _MockSessionView(session: session, controller: controller);
          },
        ),
      ),
    );
  }
}

class _MockStart extends StatelessWidget {
  const _MockStart({required this.controller});

  final MockInterviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 28.h),
      children: [
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: CustomTheme.surface,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                color: CustomTheme.primary,
                size: 36.r,
              ),
              SizedBox(height: 14.h),
              Text(
                'Quick mock',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8.h),
              Text(
                'Generate five high-frequency Android questions, answer them one by one, and get immediate scoring.',
                style: TextStyle(color: CustomTheme.textSecondary, height: 1.4),
              ),
              SizedBox(height: 18.h),
              FilledButton.icon(
                onPressed: controller.startQuickMock,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start practice'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockSessionView extends StatelessWidget {
  const _MockSessionView({required this.session, required this.controller});

  final MockSession session;
  final MockInterviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      children: [
        _SessionSummary(session: session, onRestart: controller.startQuickMock),
        SizedBox(height: 14.h),
        ...session.questions.map(
          (question) =>
              _MockQuestionCard(question: question, controller: controller),
        ),
      ],
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session, required this.onRestart});

  final MockSession session;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.answeredCount}/${session.totalCount} answered',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Score ${session.score} · ${session.status}',
                  style: TextStyle(color: CustomTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed: onRestart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _MockQuestionCard extends StatelessWidget {
  const _MockQuestionCard({required this.question, required this.controller});

  final MockQuestion question;
  final MockInterviewController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.answerResults[question.questionId];
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (question.answered)
                Icon(
                  Icons.check_circle_rounded,
                  color: CustomTheme.primary,
                  size: 20.r,
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            question.prompt,
            style: TextStyle(color: CustomTheme.textSecondary, height: 1.35),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller.answerController(question.questionId),
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Structure your answer: context, choice, tradeoff, result.',
              filled: true,
              fillColor: CustomTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          FilledButton(
            onPressed: question.answered
                ? null
                : () => controller.submitAnswer(question),
            child: Text(question.answered ? 'Submitted' : 'Submit answer'),
          ),
          if (result != null) ...[
            SizedBox(height: 12.h),
            _AnswerResult(result: result),
          ],
        ],
      ),
    );
  }
}

class _AnswerResult extends StatelessWidget {
  const _AnswerResult({required this.result});

  final MockAnswerResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: CustomTheme.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score ${result.score}',
            style: TextStyle(
              color: result.passed ? CustomTheme.primary : CustomTheme.danger,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            result.feedback,
            style: TextStyle(color: CustomTheme.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(result.standardAnswer, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}
