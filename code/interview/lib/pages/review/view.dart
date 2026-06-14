part of 'index.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReviewController>()
        ? Get.find<ReviewController>()
        : Get.put(ReviewController());

    return CustomScaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Obx(
        () => AppStateBuilder(
          state: controller.state.value,
          onRetry: controller.load,
          builder: (_) => RefreshIndicator(
            onRefresh: controller.load,
            color: CustomTheme.primary,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
              children: [
                _ReviewSummary(review: controller.review.value),
                SizedBox(height: 18.h),
                Text(
                  'Due cards',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10.h),
                if ((controller.review.value?.items ?? const <ReviewItem>[])
                    .isEmpty)
                  const _EmptyPanel(
                    text: 'No due review yet. Complete points first.',
                  )
                else
                  ...controller.review.value!.items.map(
                    (item) => _ReviewCard(item: item, controller: controller),
                  ),
                SizedBox(height: 18.h),
                Text(
                  'Wrong book',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10.h),
                if ((controller.wrongBook.value?.questions ??
                        const <InterviewQuestion>[])
                    .isEmpty)
                  const _EmptyPanel(text: 'No wrong questions yet.')
                else
                  ...controller.wrongBook.value!.questions.map(
                    _WrongQuestionCard.new,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.review});

  final TodayReview? review;

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
          _SummaryItem(label: 'Due', value: '${review?.dueCount ?? 0}'),
          _SummaryItem(
            label: 'Wrong',
            value: '${review?.wrongQuestionCount ?? 0}',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(color: CustomTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item, required this.controller});

  final ReviewItem item;
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            item.prompt,
            style: TextStyle(color: CustomTheme.textSecondary, height: 1.35),
          ),
          SizedBox(height: 10.h),
          Text(
            item.answer,
            style: TextStyle(color: CustomTheme.primary, height: 1.35),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _FeedbackButton(
                label: 'Again',
                onTap: () => controller.submitFeedback(item, 'again'),
              ),
              SizedBox(width: 8.w),
              _FeedbackButton(
                label: 'Hard',
                onTap: () => controller.submitFeedback(item, 'hard'),
              ),
              SizedBox(width: 8.w),
              _FeedbackButton(
                label: 'Good',
                onTap: () => controller.submitFeedback(item, 'good'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

class _WrongQuestionCard extends StatelessWidget {
  const _WrongQuestionCard(this.question);

  final InterviewQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.title, style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 6.h),
          Text(
            question.prompt,
            style: TextStyle(color: CustomTheme.textSecondary, height: 1.35),
          ),
          SizedBox(height: 8.h),
          Text(
            question.answer,
            style: TextStyle(color: CustomTheme.primary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(text, style: TextStyle(color: CustomTheme.textSecondary)),
    );
  }
}
