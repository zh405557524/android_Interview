part of 'index.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  late final MembershipController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(MembershipController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        toolbarHeight: 48.h,
        leadingWidth: 52.w,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          tooltip: '返回',
        ),
        title: Text(
          'VIP会员',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
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
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Obx(
                  () => AppStateBuilder(
                    state: controller.pageState,
                    loadingMessage: '加载会员套餐...',
                    emptyMessage: '暂无可购买会员套餐',
                    errorMessage: controller.errorMessage.value ?? '会员套餐加载失败',
                    onRetry: controller.loadPlans,
                    builder: (_) => Obx(
                      () => ListView(
                        padding: EdgeInsets.fromLTRB(18.w, 28.h, 18.w, 170.h),
                        children: [
                          _MembershipHero(controller: controller),
                          SizedBox(height: 20.h),
                          ...controller.plans.map((plan) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 15.h),
                              child: _MembershipPlanCard(
                                plan: plan,
                                selected:
                                    controller.selectedPlanId.value == plan.id,
                                onTap: () => controller.selectPlan(plan.id),
                              ),
                            );
                          }),
                          _MembershipAgreement(controller: controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 15.w,
              right: 15.w,
              bottom: 34.h,
              child: Obx(
                () => AppButton(
                  label: '立即充值',
                  loading: controller.submitting.value,
                  loadingLabel: '支付中',
                  disabled:
                      controller.pageState != ViewState.success &&
                      controller.pageState != ViewState.submitting,
                  onPressed: () => controller.submit(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipHero extends StatelessWidget {
  const _MembershipHero({required this.controller});

  final MembershipController controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        children: [
          Image.asset(
            AppAssets.iconInterests,
            width: 130.r,
            height: 102.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(height: 12.h),
          Text(
            '获取全部特权',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 24.h),
          ...controller.benefits.map((benefit) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.iconCheck,
                    width: 14.r,
                    height: 14.r,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    benefit,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MembershipPlanCard extends StatelessWidget {
  const _MembershipPlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final MembershipPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 17.w),
        decoration: BoxDecoration(
          color: selected
              ? CustomTheme.primary.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected
                ? CustomTheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              AppAssets.iconPrivilege,
              width: 36.r,
              height: 36.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    plan.priceText,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Text(
              plan.periodLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10.w),
            AppSelectionIcon(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _MembershipAgreement extends StatelessWidget {
  const _MembershipAgreement({required this.controller});

  final MembershipController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          InkWell(
            onTap: () =>
                controller.toggleAgreement(!controller.agreementAccepted.value),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: AppAgreementIcon(
                selected: controller.agreementAccepted.value,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _MembershipAgreementText('我已阅读并同意'),
                _MembershipAgreementLink(
                  label: '《会员服务协议》',
                  onTap: () => context.pushNamed(
                    RouteName.webview,
                    queryParameters: <String, String>{
                      'key': 'membership-agreement',
                    },
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

class _MembershipAgreementText extends StatelessWidget {
  const _MembershipAgreementText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Colors.white70, fontSize: 12.sp),
    );
  }
}

class _MembershipAgreementLink extends StatelessWidget {
  const _MembershipAgreementLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Text(
        label,
        style: TextStyle(
          color: CustomTheme.primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: CustomTheme.primary,
        ),
      ),
    );
  }
}
