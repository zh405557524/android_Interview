part of 'index.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Obx(
      () => AppStateBuilder(
        state: controller.state.value,
        onRetry: controller.loadHome,
        builder: (_) {
          final overview = controller.overview.value;
          return RefreshIndicator(
            onRefresh: controller.loadHome,
            color: CustomTheme.primary,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              children: [
                _HeroSummary(overview: overview),
                SizedBox(height: 16.h),
                _QuickActions(controller: controller),
                SizedBox(height: 20.h),
                _SectionHeader(
                  title: 'Knowledge map',
                  actionText: 'View all',
                  onTap: () => controller.openKnowledge(context),
                ),
                SizedBox(height: 10.h),
                ...overview.categories.map(
                  (category) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _CategoryCard(
                      category: category,
                      onTap: () => controller.openCategory(context, category),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _SectionHeader(title: 'High-frequency questions'),
                SizedBox(height: 10.h),
                ...overview.featuredQuestions
                    .take(4)
                    .map((question) => _QuestionCard(question: question)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.overview});

  final OfferHomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offer Hunter',
              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6.h),
            Text(
              'Android interview prep built around knowledge, review, and mock practice.',
              style: TextStyle(
                color: CustomTheme.textSecondary,
                fontSize: 13.sp,
                height: 1.35,
              ),
            ),
            SizedBox(height: 18.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                minHeight: 8.h,
                value: (summary.completionRate.clamp(0, 100) / 100).toDouble(),
                color: CustomTheme.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _Metric(
                  label: 'Completed',
                  value: '${summary.completedPoints}/${summary.totalPoints}',
                ),
                _Metric(label: 'Review', value: '${summary.todayReviewCount}'),
                _Metric(label: 'Wrong', value: '${summary.wrongQuestionCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(color: CustomTheme.textSecondary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.menu_book_rounded,
          label: 'Learn',
          onTap: () => controller.openKnowledge(context),
        ),
        SizedBox(width: 10.w),
        _ActionButton(
          icon: Icons.record_voice_over_rounded,
          label: 'Mock',
          onTap: () => controller.openMock(context),
        ),
        SizedBox(width: 10.w),
        _ActionButton(
          icon: Icons.restart_alt_rounded,
          label: 'Review',
          onTap: () => controller.openReview(context),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Ink(
          height: 72.h,
          decoration: BoxDecoration(
            color: CustomTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: CustomTheme.primary, size: 22.r),
              SizedBox(height: 7.h),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionText, this.onTap});

  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
          ),
        ),
        if (actionText != null)
          TextButton(onPressed: onTap, child: Text(actionText!)),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final KnowledgeCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Ink(
        decoration: BoxDecoration(
          color: CustomTheme.surface,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: CustomTheme.primary.withValues(alpha: 0.14),
                child: Icon(Icons.school_rounded, color: CustomTheme.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CustomTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                '${category.completedPoints}/${category.totalPoints}',
                style: TextStyle(
                  color: CustomTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6.h),
          Text(
            question.prompt,
            style: TextStyle(
              color: CustomTheme.textSecondary,
              fontSize: 12.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
