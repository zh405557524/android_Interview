part of 'index.dart';

class KnowledgePage extends StatelessWidget {
  const KnowledgePage({super.key, this.categoryId});

  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    final tag = categoryId ?? 'root';
    final controller = Get.isRegistered<KnowledgeController>(tag: tag)
        ? Get.find<KnowledgeController>(tag: tag)
        : Get.put(KnowledgeController(initialCategoryId: categoryId), tag: tag);

    return CustomScaffold(
      appBar: AppBar(
        title: Text(categoryId == null ? 'Knowledge' : 'Category'),
      ),
      body: Obx(
        () => AppStateBuilder(
          state: controller.state.value,
          onRetry: controller.load,
          builder: (_) => controller.isDetailMode
              ? _CategoryDetail(controller: controller)
              : _CategoryList(controller: controller),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.controller});

  final KnowledgeController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: CustomTheme.primary,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        itemCount: controller.categories.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          return _KnowledgeCategoryTile(
            category: category,
            onTap: () => controller.openCategory(context, category),
          );
        },
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({required this.controller});

  final KnowledgeController controller;

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail.value;
    if (detail == null) {
      return const SizedBox.shrink();
    }
    return RefreshIndicator(
      onRefresh: controller.load,
      color: CustomTheme.primary,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        children: [
          _KnowledgeCategoryTile(category: detail.category, onTap: () {}),
          SizedBox(height: 16.h),
          ...detail.modules.map(
            (module) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _ModuleSection(module: module, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeCategoryTile extends StatelessWidget {
  const _KnowledgeCategoryTile({required this.category, required this.onTap});

  final KnowledgeCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Ink(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: CustomTheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${category.completedPoints}/${category.totalPoints}',
                  style: TextStyle(
                    color: CustomTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              category.description,
              style: TextStyle(color: CustomTheme.textSecondary, height: 1.35),
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                value: category.progress.clamp(0, 1).toDouble(),
                minHeight: 6.h,
                color: CustomTheme.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({required this.module, required this.controller});

  final KnowledgeModule module;
  final KnowledgeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          module.title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
        ),
        if (module.subtitle.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            module.subtitle,
            style: TextStyle(color: CustomTheme.textSecondary, fontSize: 12.sp),
          ),
        ],
        SizedBox(height: 10.h),
        ...module.points.map(
          (point) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _PointTile(
              point: point,
              onTap: () => controller.openPoint(context, point),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({required this.point, required this.onTap});

  final KnowledgePointItem point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Ink(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: CustomTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              point.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: point.completed
                  ? CustomTheme.primary
                  : CustomTheme.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${point.estimatedMinutes} min · ${point.questionCount} questions',
                    style: TextStyle(
                      color: CustomTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
