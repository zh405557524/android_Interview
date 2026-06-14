part of 'index.dart';

/// App 任务中心页面，承载总积分、连续签到和每日邀请任务。
class TaskCenterPage extends StatefulWidget {
  const TaskCenterPage({super.key});

  @override
  State<TaskCenterPage> createState() => _TaskCenterPageState();
}

/// 任务中心页面状态，负责创建并释放独立 controller。
class _TaskCenterPageState extends State<TaskCenterPage> {
  /// 页面专属控制器，避免与其他页面共享任务中心状态。
  late final TaskCenterController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(TaskCenterController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: CustomTheme.background,
      appBar: AppBar(
        toolbarHeight: 48.h,
        leadingWidth: 52.w,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          tooltip: '返回',
        ),
        title: Text(
          '任务中心',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
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
          child: Obx(
            () => AppStateBuilder(
              state: controller.pageState,
              loadingMessage: '加载任务中心...',
              errorMessage: controller.errorMessage.value ?? '任务中心加载失败',
              onRetry: controller.loadOverview,
              builder: (_) {
                final overview = controller.overview.value;
                if (overview == null) {
                  return const SizedBox.shrink();
                }
                return RefreshIndicator(
                  color: CustomTheme.primary,
                  backgroundColor: CustomTheme.surface,
                  onRefresh: () => controller.loadOverview(silent: true),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 34.h),
                    children: [
                      _PointsHeader(points: overview.totalPoints),
                      SizedBox(height: 14.h),
                      _CheckInCard(
                        checkIn: overview.checkIn,
                        signing: controller.signing.value,
                        onCheckIn: controller.checkIn,
                      ),
                      SizedBox(height: 14.h),
                      _DailyTasksCard(
                        task: overview.inviteTask,
                        onInvite: () => controller.openInvite(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 顶部总积分卡片，使用 App 深色体系和主色强调积分余额。
class _PointsHeader extends StatelessWidget {
  const _PointsHeader({required this.points});

  /// 当前用户可用总积分。
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132.h,
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D3D10), Color(0xFF5E8C0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10.w,
            bottom: -24.h,
            child: Icon(
              Icons.task_alt_rounded,
              color: Colors.white.withValues(alpha: 0.08),
              size: 118.r,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '完成任务，领取积分',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '连续签到与邀请好友可获得更多创作积分',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                height: 38.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(19.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.control_point_duplicate,
                      color: CustomTheme.primary,
                      size: 18.r,
                    ),
                    SizedBox(width: 7.w),
                    Text(
                      '总积分：$points',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 连续签到卡片，展示 7 天奖励节点和签到领取按钮。
class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.checkIn,
    required this.signing,
    required this.onCheckIn,
  });

  /// 连续签到状态与 7 天奖励数据。
  final TaskCheckInOverview checkIn;

  /// 签到接口是否正在提交。
  final bool signing;

  /// 点击签到按钮时触发的领取动作。
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return _TaskCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '连续签到领积分',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CustomTheme.primary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '签到马上领取积分，连续天数越多，积分越多',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in checkIn.days) _CheckInDayNode(day: day),
            ],
          ),
          SizedBox(height: 22.h),
          AppButton(
            label: checkIn.signedToday ? '已签到' : '签到领取',
            loadingLabel: '签到中',
            loading: signing,
            disabled: checkIn.signedToday,
            onPressed: onCheckIn,
            icon: checkIn.signedToday
                ? Icons.check_circle_rounded
                : Icons.bolt_rounded,
            backgroundColor: checkIn.signedToday
                ? Colors.white.withValues(alpha: 0.16)
                : CustomTheme.primary,
            foregroundColor: checkIn.signedToday
                ? Colors.white70
                : Colors.black,
          ),
        ],
      ),
    );
  }
}

/// 连续签到卡片中的单个天数奖励节点。
class _CheckInDayNode extends StatelessWidget {
  const _CheckInDayNode({required this.day});

  /// 当前天数节点的数据。
  final TaskCheckInDay day;

  @override
  Widget build(BuildContext context) {
    final highlighted = day.current || day.checked;
    return SizedBox(
      width: 42.w,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted
                  ? CustomTheme.primary
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: day.current
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: day.checked
                ? Icon(Icons.check_rounded, color: Colors.black, size: 20.r)
                : Text(
                    '+${day.rewardPoints}',
                    style: TextStyle(
                      color: highlighted ? Colors.black : CustomTheme.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          SizedBox(height: 7.h),
          Text(
            day.day == 1 ? '1天' : '${day.day}天',
            maxLines: 1,
            style: TextStyle(
              color: day.current
                  ? CustomTheme.primary
                  : Colors.white.withValues(alpha: 0.66),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 每日任务卡片；第一版只展示邀请好友任务。
class _DailyTasksCard extends StatelessWidget {
  const _DailyTasksCard({required this.task, required this.onInvite});

  /// 邀请好友任务数据；为空时展示无任务状态。
  final TaskCenterItem? task;

  /// 点击邀请任务按钮时跳转到推广素材页。
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final item = task;
    return _TaskCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '每日任务',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CustomTheme.primary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 18.h),
          if (item == null)
            Text(
              '暂无可做任务',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 13.sp,
              ),
            )
          else
            _InviteTaskRow(task: item, onInvite: onInvite),
        ],
      ),
    );
  }
}

/// 邀请好友任务行，展示任务进度、奖励和跳转按钮。
class _InviteTaskRow extends StatelessWidget {
  const _InviteTaskRow({required this.task, required this.onInvite});

  /// 邀请好友任务展示数据。
  final TaskCenterItem task;

  /// 点击按钮时进入推广素材页面。
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CustomTheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: CustomTheme.primary,
            size: 24.r,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      task.title.isEmpty ? '邀请好友领积分' : task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _ProgressBadge(text: task.progressText),
                ],
              ),
              SizedBox(height: 7.h),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  Text(
                    task.description.isEmpty
                        ? '邀请好友注册，复用邀请奖励'
                        : task.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    task.rewardText,
                    style: TextStyle(
                      color: CustomTheme.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: 78.w,
          height: 38.h,
          child: FilledButton(
            onPressed: task.enabled ? onInvite : null,
            style: FilledButton.styleFrom(
              backgroundColor: CustomTheme.primary,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19.r),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              task.actionText.isEmpty ? '去邀请' : task.actionText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

/// 每日任务进度胶囊。
class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.text});

  /// 展示给用户的进度文本，例如 `0/1`。
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CustomTheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: CustomTheme.primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// 任务中心暗色卡片容器，统一签到与每日任务卡片视觉。
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.child});

  /// 卡片内部实际业务内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}
