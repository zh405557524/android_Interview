part of 'index.dart';

class KnowledgePointPage extends StatelessWidget {
  const KnowledgePointPage({required this.pointId, super.key});

  final String pointId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<KnowledgePointController>(tag: pointId)
        ? Get.find<KnowledgePointController>(tag: pointId)
        : Get.put(KnowledgePointController(pointId: pointId), tag: pointId);

    return CustomScaffold(
      appBar: AppBar(title: const Text('Knowledge point')),
      body: Obx(
        () => AppStateBuilder(
          state: controller.state.value,
          onRetry: controller.load,
          builder: (_) {
            final detail = controller.detail.value;
            if (detail == null) {
              return const SizedBox.shrink();
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
              children: [
                _PointHeader(detail: detail),
                SizedBox(height: 16.h),
                ...detail.blocks.map((block) => _BlockCard(block: block)),
                SizedBox(height: 12.h),
                Text(
                  'Practice questions',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10.h),
                ...detail.questions.map(
                  (question) => _QuestionCard(question: question),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Obx(() {
        final detail = controller.detail.value;
        if (detail == null) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: FilledButton.icon(
              onPressed: detail.completed || controller.completing.value
                  ? null
                  : controller.complete,
              icon: Icon(
                detail.completed ? Icons.check_rounded : Icons.done_all_rounded,
              ),
              label: Text(detail.completed ? 'Completed' : 'Mark as completed'),
            ),
          ),
        );
      }),
    );
  }
}

class _PointHeader extends StatelessWidget {
  const _PointHeader({required this.detail});

  final KnowledgePointDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            detail.summary,
            style: TextStyle(color: CustomTheme.textSecondary, height: 1.35),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _Chip(label: detail.difficulty),
              _Chip(label: '${detail.estimatedMinutes} min'),
              ...detail.tags.map((tag) => _Chip(label: tag)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block});

  final KnowledgeBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: CustomTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            block.content,
            style: TextStyle(height: 1.45, color: CustomTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

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
          Text(
            question.title,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            question.prompt,
            style: TextStyle(color: CustomTheme.textSecondary, height: 1.35),
          ),
          SizedBox(height: 10.h),
          Text(
            question.answer,
            style: TextStyle(color: CustomTheme.primary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        child: Text(label, style: TextStyle(fontSize: 11.sp)),
      ),
    );
  }
}
