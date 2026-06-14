part of 'index.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  late final InviteController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '收益',
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载邀请信息...',
          errorMessage: controller.errorMessage.value ?? '邀请信息加载失败',
          onRetry: controller.loadInvite,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadInvite),
          builder: (_) => RefreshIndicator(
            color: invitePrimary,
            backgroundColor: const Color(0xFF101C10),
            onRefresh: controller.loadInvite,
            child: _EarningsView(
              userLabel: controller.userStore.isLoggedIn
                  ? controller.userStore.maskedPhone.value
                  : '未登录',
              agentLevel: controller.overview.value?.agentLevel ?? 1,
              withdrawableCents:
                  controller.earningSummary.value?.withdrawableCents ??
                  controller.overview.value?.withdrawableCents ??
                  0,
              todayCents:
                  controller.earningSummary.value?.todayEarningsCents ?? 0,
              yesterdayCents:
                  controller.earningSummary.value?.yesterdayEarningsCents ?? 0,
              totalCents:
                  controller.earningSummary.value?.totalEarningsCents ??
                  controller.overview.value?.totalEarningsCents ??
                  0,
              onRecordsTap: () => context.pushNamed(RouteName.inviteRecords),
              onLedgersTap: () => context.pushNamed(RouteName.inviteLedgers),
              onWithdrawalsTap: () =>
                  context.pushNamed(RouteName.inviteWithdrawals),
              onMaterialsTap: () =>
                  context.pushNamed(RouteName.inviteMaterials),
              onBindTap: () => context.pushNamed(RouteName.inviteBind),
              onRulesTap: () => context.pushNamed(RouteName.inviteRules),
              onWithdrawalTap: () =>
                  context.pushNamed(RouteName.inviteWithdrawal),
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningsView extends StatelessWidget {
  const _EarningsView({
    required this.userLabel,
    required this.agentLevel,
    required this.withdrawableCents,
    required this.todayCents,
    required this.yesterdayCents,
    required this.totalCents,
    required this.onRecordsTap,
    required this.onLedgersTap,
    required this.onWithdrawalsTap,
    required this.onMaterialsTap,
    required this.onBindTap,
    required this.onRulesTap,
    required this.onWithdrawalTap,
  });

  final String userLabel;
  final int agentLevel;
  final int withdrawableCents;
  final int todayCents;
  final int yesterdayCents;
  final int totalCents;
  final VoidCallback onRecordsTap;
  final VoidCallback onLedgersTap;
  final VoidCallback onWithdrawalsTap;
  final VoidCallback onMaterialsTap;
  final VoidCallback onBindTap;
  final VoidCallback onRulesTap;
  final VoidCallback onWithdrawalTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('invite-earnings'),
      padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 36.h),
      children: [
        Row(
          children: [
            Image.asset(
              AppAssets.iconHead,
              width: 58.r,
              height: 58.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _AgentBadge(level: agentLevel),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _IncomeHero(
          withdrawableCents: withdrawableCents,
          todayCents: todayCents,
          yesterdayCents: yesterdayCents,
          totalCents: totalCents,
          onWithdrawalTap: onWithdrawalTap,
        ),
        SizedBox(height: 20.h),
        const InviteGreenSectionTitle('数据中心'),
        SizedBox(height: 10.h),
        InviteMenuRow(title: '邀请列表', onTap: onRecordsTap),
        SizedBox(height: 12.h),
        InviteMenuRow(title: '收益明细', onTap: onLedgersTap),
        SizedBox(height: 12.h),
        InviteMenuRow(title: '提现记录', onTap: onWithdrawalsTap),
        SizedBox(height: 20.h),
        const InviteGreenSectionTitle('推广工具'),
        SizedBox(height: 10.h),
        InviteMenuRow(title: '推广素材', onTap: onMaterialsTap),
        SizedBox(height: 12.h),
        InviteMenuRow(title: '绑定邀请人', onTap: onBindTap),
        SizedBox(height: 12.h),
        InviteMenuRow(title: '会员佣金说明', onTap: onRulesTap),
      ],
    );
  }
}

class _AgentBadge extends StatelessWidget {
  const _AgentBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF101D11),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Text(
          '推广达人V$level',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IncomeHero extends StatelessWidget {
  const _IncomeHero({
    required this.withdrawableCents,
    required this.todayCents,
    required this.yesterdayCents,
    required this.totalCents,
    required this.onWithdrawalTap,
  });

  final int withdrawableCents;
  final int todayCents;
  final int yesterdayCents;
  final int totalCents;
  final VoidCallback onWithdrawalTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16220D), Color(0xFF010401), Color(0xFF1E2C08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '可提现收益  (元)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '¥',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              inviteFormatYuan(withdrawableCents),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 76.w,
                    height: 32.h,
                    child: FilledButton(
                      onPressed: onWithdrawalTap,
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                      ),
                      child: Text(
                        '立即提现',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 74.h,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                _IncomeMetric(label: '今日收益（元）', cents: todayCents),
                const _MetricDivider(),
                _IncomeMetric(label: '昨日收益（元）', cents: yesterdayCents),
                const _MetricDivider(),
                _IncomeMetric(label: '累计收益（元）', cents: totalCents),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeMetric extends StatelessWidget {
  const _IncomeMetric({required this.label, required this.cents});

  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            inviteFormatYuan(cents),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: inviteTextMuted, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28.h,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}
