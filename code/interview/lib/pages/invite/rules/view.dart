part of 'index.dart';

class InviteRulesPage extends StatefulWidget {
  const InviteRulesPage({super.key});

  @override
  State<InviteRulesPage> createState() => _InviteRulesPageState();
}

class _InviteRulesPageState extends State<InviteRulesPage> {
  late final InviteRulesController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteRulesController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '会员佣金说明',
      light: true,
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载佣金规则...',
          errorMessage: controller.errorMessage.value ?? '佣金规则加载失败',
          onRetry: controller.loadRules,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadRules),
          builder: (_) => _CommissionRulesContent(
            overview: controller.overview.value,
          ),
        ),
      ),
    );
  }
}

class _CommissionRulesContent extends StatelessWidget {
  const _CommissionRulesContent({required this.overview});

  final InviteOverview? overview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('invite-commission-rules'),
      padding: EdgeInsets.fromLTRB(0, 0, 0, 22.h),
      children: [
        Container(
          height: 208.h,
          padding: EdgeInsets.fromLTRB(21.w, 18.h, 21.w, 20.h),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4BB0FF), Color(0xFFDDF1FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '剧说助手',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '软件代理商分佣',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '直接收益按个人代理等级计算，间接收益固定 10% 且仅一层。',
                style: TextStyle(
                  color: const Color(0xFF245C9E),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 0),
          child: Column(
            children: [
              _LightRuleCard(
                title: '官方陪跑课程分佣',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '会员定价',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      '¥998',
                      style: TextStyle(
                        color: const Color(0xFF0064FF),
                        fontSize: 38.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'x ${overview?.directCommissionRate ?? 10}%',
                      style: TextStyle(
                        color: const Color(0xFF0064FF),
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              _AgentRuleCard(
                ribbon: '初级代理',
                iconColor: const Color(0xFF2F78FF),
                rate: '10%',
                condition: '开通会员即可成为 初级代理商',
              ),
              SizedBox(height: 16.h),
              _AgentRuleCard(
                ribbon: '中级代理',
                iconColor: const Color(0xFF9461FF),
                rate: '20%',
                condition: '升级条件: 直推10名初级代理商',
              ),
              SizedBox(height: 16.h),
              _AgentRuleCard(
                ribbon: '高级代理',
                iconColor: const Color(0xFFFFA83A),
                rate: '30%',
                condition: '升级条件: 直推30名初级代理商',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LightRuleCard extends StatelessWidget {
  const _LightRuleCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DB9FF).withValues(alpha: 0.18),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFD4E6FF)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AgentRuleCard extends StatelessWidget {
  const _AgentRuleCard({
    required this.ribbon,
    required this.iconColor,
    required this.rate,
    required this.condition,
  });

  final String ribbon;
  final Color iconColor;
  final String rate;
  final String condition;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 22.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DB9FF).withValues(alpha: 0.14),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -48.h,
            left: 88.w,
            right: 88.w,
            child: Container(
              height: 40.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withValues(alpha: 0.58)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  ribbon,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 100.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.28),
                        blurRadius: 12.r,
                        offset: Offset(0, 5.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 26.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '充值金额',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 21.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'x$rate',
                            style: TextStyle(
                              color: const Color(0xFF0064FF),
                              fontSize: 27.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        condition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
