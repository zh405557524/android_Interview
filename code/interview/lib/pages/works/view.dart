part of 'index.dart';

class WorksPage extends StatefulWidget {
  const WorksPage({super.key});

  @override
  State<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends State<WorksPage> {
  late final WorksController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(WorksController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071306), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Obx(
              () => RefreshIndicator(
                onRefresh: controller.refreshWorks,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    15.w,
                    12.h,
                    15.w,
                    controller.isManaging.value ? 166.h : 110.h,
                  ),
                  children: [
                    const _WorksTip(),
                    SizedBox(height: 20.h),
                    _WorkFilterBar(controller: controller),
                    SizedBox(height: 15.h),
                    SizedBox(
                      height: controller.pageState == ViewState.success
                          ? null
                          : 360.h,
                      child: AppStateBuilder(
                        state: controller.pageState,
                        loadingMessage: '加载作品中...',
                        errorMessage: controller.errorMessage.value ?? '作品加载失败',
                        onRetry: controller.loadWorks,
                        empty: _WorksEmpty(
                          onCreate: () {
                            if (!controller.userStore.isLoggedIn) {
                              context.pushNamed(RouteName.login);
                              return;
                            }
                            context.pushNamed(RouteName.creationVideo);
                          },
                        ),
                        builder: (_) => _WorksGrid(controller: controller),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(
              () => controller.isManaging.value
                  ? Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _WorksBatchBar(controller: controller),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorksBatchBar extends StatelessWidget {
  const _WorksBatchBar({required this.controller});

  final WorksController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF11161D),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Obx(() {
          final hasSelection = controller.selectedCount > 0;
          final hiding = controller.hidingWorks.value;
          return Row(
            children: [
              Expanded(
                child: Text(
                  '已选 ${controller.selectedCount} 个',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: hiding ? null : controller.toggleSelectAllWorks,
                child: Text(
                  controller.allSelectableSelected ? '取消全选' : '全选',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(
                width: 88.w,
                height: 38.h,
                child: FilledButton(
                  onPressed: hasSelection && !hiding
                      ? () => _confirmHideWorks(context)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3333),
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.36,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    hiding ? '删除中' : '删除',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirmHideWorks(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '删除作品',
      message: '删除后将不在我的作品中展示',
    );
    if (confirmed != true) {
      return;
    }
    await controller.hideSelectedWorks();
  }
}

class _WorksTip extends StatelessWidget {
  const _WorksTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(17.r),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.iconCaution,
            width: 20.r,
            height: 20.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: 8.w),
          Text(
            '温馨提示：作品保留7天',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkFilterBar extends StatelessWidget {
  const _WorkFilterBar({required this.controller});

  final WorksController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.visibleCategories;
      return SizedBox(
        height: 22.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => SizedBox(width: 24.w),
          itemBuilder: (context, index) {
            final category = categories[index];
            final selected = controller.selectedCategory.value == category;
            return InkWell(
              onTap: () => controller.selectCategory(category),
              child: Text(
                category.label,
                style: TextStyle(
                  color: selected ? CustomTheme.primary : Colors.white54,
                  fontSize: 16.sp,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _WorksEmpty extends StatelessWidget {
  const _WorksEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.iconNoRecord,
            width: 50.r,
            height: 50.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(height: 10.h),
          Text(
            '暂无记录',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: 104.w,
            height: 34.h,
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: Image.asset(
                AppAssets.iconAdd,
                width: 14.r,
                height: 14.r,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              label: Text(
                '立即创造',
                style: TextStyle(fontSize: 12.sp, letterSpacing: 1),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                backgroundColor: CustomTheme.primary.withValues(alpha: 0.1),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorksGrid extends StatelessWidget {
  const _WorksGrid({required this.controller});

  final WorksController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.works.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 13.w,
        mainAxisSpacing: 18.h,
        childAspectRatio: 108 / 196,
      ),
      itemBuilder: (context, index) {
        final work = controller.works[index];
        return Obx(() {
          final managing = controller.isManaging.value;
          return _WorkCard(
            work: work,
            isManaging: managing,
            isSelected: controller.isWorkSelected(work),
            isSelectable: controller.isWorkSelectable(work),
            onTap: managing
                ? () => controller.toggleWorkSelection(work)
                : () => context.pushNamed(
                    RouteName.workDetail,
                    pathParameters: <String, String>{'id': work.id},
                  ),
            onMore: () => controller.showMoreActions(work),
          );
        });
      },
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({
    required this.work,
    required this.isManaging,
    required this.isSelected,
    required this.isSelectable,
    required this.onTap,
    required this.onMore,
  });

  final Work work;
  final bool isManaging;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final coverUrl = _coverImageUrl(work.coverUrl);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: _coverGradient(work.workType),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Stack(
                children: [
                  if (coverUrl.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        gradient: const LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.58, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5.w,
                    top: 5.h,
                    child: _WorkStatusBadge(status: work.status),
                  ),
                  Positioned(
                    left: 6.w,
                    right: 6.w,
                    bottom: 6.h,
                    child: Text(
                      work.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFF6FFFF),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (isManaging)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  if (isManaging)
                    Positioned(
                      right: 7.w,
                      top: 7.h,
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? CustomTheme.primary
                            : Colors.white.withValues(
                                alpha: isSelectable ? 0.92 : 0.34,
                              ),
                        size: 21.r,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  work.createdAtText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                ),
              ),
              if (!isManaging)
                InkWell(
                  onTap: onMore,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Icon(Icons.more_horiz_rounded, size: 20.r),
                )
              else
                SizedBox(width: 20.r, height: 20.r),
            ],
          ),
        ],
      ),
    );
  }

  LinearGradient _coverGradient(WorkType category) {
    return switch (category) {
      WorkType.shortSeries => const LinearGradient(
        colors: [Color(0xFF42341F), Color(0xFF0B100C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      WorkType.movie => const LinearGradient(
        colors: [Color(0xFF3A284C), Color(0xFF071306)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      WorkType.tvSeries => const LinearGradient(
        colors: [Color(0xFF1D4935), Color(0xFF071306)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      WorkType.all => const LinearGradient(
        colors: [Color(0xFF2B3740), Color(0xFF071306)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    };
  }

  String _coverImageUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }
    if (!value.startsWith('/')) {
      return value;
    }
    final baseUrl = HttpService.to.baseUrl.trim();
    if (baseUrl.isEmpty) {
      return '';
    }
    return Uri.parse(baseUrl).resolve(value).toString();
  }
}

class _WorkStatusBadge extends StatelessWidget {
  const _WorkStatusBadge({required this.status});

  final WorkStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21.h,
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _label {
    return switch (status) {
      WorkStatus.draft => '草稿',
      WorkStatus.queued => '排队',
      WorkStatus.generating => '生成中',
      WorkStatus.succeeded => '完成',
      WorkStatus.failed => '失败',
      WorkStatus.expired => '过期',
    };
  }
}
