part of 'index.dart';

class OfferProfilePage extends StatelessWidget {
  const OfferProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<OfferProfileController>()
        ? Get.find<OfferProfileController>()
        : Get.put(OfferProfileController());

    return CustomScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => controller.openLogin(context),
            child: const Text('Login'),
          ),
        ],
      ),
      body: Obx(
        () => AppStateBuilder(
          state: controller.state.value,
          onRetry: controller.load,
          builder: (_) {
            final dashboard = controller.dashboard.value;
            if (dashboard == null) {
              return const SizedBox.shrink();
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              color: CustomTheme.primary,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                children: [
                  _ProfileSummary(dashboard: dashboard),
                  SizedBox(height: 18.h),
                  Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...dashboard.achievements.map(_AchievementTile.new),
                  SizedBox(height: 18.h),
                  Text(
                    'Recent mock sessions',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (dashboard.recentMockSessions.isEmpty)
                    const _EmptyPanel(text: 'No mock sessions yet.')
                  else
                    ...dashboard.recentMockSessions.map(_MockSessionTile.new),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.dashboard});

  final ProfileDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning dashboard',
            style: TextStyle(fontSize: 21.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _ProfileMetric(
                label: 'Progress',
                value: '${summary.completionRate.toStringAsFixed(0)}%',
              ),
              _ProfileMetric(
                label: 'Streak',
                value: '${dashboard.streakDays}d',
              ),
              _ProfileMetric(
                label: 'Minutes',
                value: '${dashboard.totalStudyMinutes}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

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
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(color: CustomTheme.textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile(this.achievement);

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? CustomTheme.surfaceHigh
            : CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            achievement.unlocked
                ? Icons.verified_rounded
                : Icons.lock_outline_rounded,
            color: achievement.unlocked
                ? CustomTheme.primary
                : CustomTheme.textSecondary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4.h),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: CustomTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockSessionTile extends StatelessWidget {
  const _MockSessionTile(this.session);

  final MockSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${session.mode} · ${session.answeredCount}/${session.totalCount}',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${session.score}',
            style: TextStyle(
              color: CustomTheme.primary,
              fontWeight: FontWeight.w900,
            ),
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
