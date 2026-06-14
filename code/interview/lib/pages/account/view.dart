part of 'index.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AccountController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(AccountController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071306), Color(0xFF030504)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(15.w, 52.h, 15.w, 110.h),
            children: [
              _AccountHero(controller: controller),
              SizedBox(height: 20.h),
              _ShortcutPanel(controller: controller),
              SizedBox(height: 10.h),
              _SettingsEntry(
                title: '任务中心',
                onTap: () => _openWhenLoggedIn(
                  context,
                  controller,
                  () => context.pushNamed(RouteName.taskCenter),
                ),
              ),
              SizedBox(height: 13.h),
              _SettingsEntry(
                title: '支付订单',
                onTap: () => _openWhenLoggedIn(
                  context,
                  controller,
                  () => context.pushNamed(RouteName.paymentOrders),
                ),
              ),
              SizedBox(height: 13.h),
              _SettingsEntry(
                title: '兑换码',
                onTap: () => _openWhenLoggedIn(
                  context,
                  controller,
                  () => context.pushNamed(RouteName.redeemCode),
                ),
              ),
              SizedBox(height: 13.h),
              _SettingsEntry(
                title: '意见反馈',
                onTap: () => context.pushNamed(RouteName.feedback),
              ),
              SizedBox(height: 13.h),
              _SettingsEntry(
                title: '更多设置',
                onTap: () => context.pushNamed(RouteName.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.controller});

  final AccountController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userStore;

      return Container(
        height: 184.h,
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 17.w, 17.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3E5311), Color(0xFF5F8B0E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24.r,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  alignment: Alignment.center,
                  child: Image.asset(
                    AppAssets.iconHead,
                    width: 48.r,
                    height: 48.r,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isLoggedIn ? user.maskedPhone.value : '未登录',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.36,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      if (user.isLoggedIn)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '邀请码:${user.inviteCode.value}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFBBC7B2),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: controller.copyInviteCode,
                              icon: Image.asset(
                                AppAssets.iconCopy,
                                width: 15.r,
                                height: 15.r,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                              ),
                              constraints: BoxConstraints.tightFor(
                                width: 28.r,
                                height: 28.r,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        )
                      else
                        Text(
                          '登录后查看积分、作品和邀请奖励',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFBBC7B2),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (user.isLoggedIn) _PointsPill(points: user.points.value),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 312.w,
              height: 45.h,
              child: FilledButton(
                onPressed: () {
                  if (!user.isLoggedIn) {
                    context.pushNamed(RouteName.login);
                    return;
                  }
                  context.pushNamed(RouteName.membership);
                },
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: CustomTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.5.r),
                  ),
                ),
                child: Text(
                  user.isLoggedIn
                      ? (user.isVip.value ? 'VIP已开通, 查看会员权益' : '开通VIP, 解锁全部功能')
                      : '立即登录',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.iconIntegral,
            width: 22.r,
            height: 22.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: 4.w),
          Text(
            '$points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel({required this.controller});

  final AccountController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF999999).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ShortcutItem(
            iconAsset: AppAssets.iconTelegram,
            label: '邀请好友',
            onTap: () => _openWhenLoggedIn(
              context,
              controller,
              () => context.pushNamed(RouteName.invite),
            ),
          ),
          _ShortcutItem(
            iconAsset: AppAssets.iconCalendar,
            label: '积分明细',
            onTap: () => _openWhenLoggedIn(
              context,
              controller,
              () => context.pushNamed(RouteName.pointsLedger),
            ),
          ),
          _ShortcutItem(
            iconAsset: AppAssets.iconServer,
            label: '积分充值',
            onTap: () => _openWhenLoggedIn(
              context,
              controller,
              () => context.pushNamed(RouteName.pointsRecharge),
            ),
          ),
          _ShortcutItem(
            iconAsset: AppAssets.iconHeadphones,
            label: '联系客服',
            onTap: () => CustomToast.text('客服能力待接入'),
          ),
        ],
      ),
    );
  }
}

void _openWhenLoggedIn(
  BuildContext context,
  AccountController controller,
  VoidCallback action,
) {
  if (!controller.userStore.isLoggedIn) {
    context.pushNamed(RouteName.login);
    return;
  }
  action();
}

class _ShortcutItem extends StatelessWidget {
  const _ShortcutItem({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 58.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 24.r,
              height: 24.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: BoxDecoration(
          color: const Color(0xFF999999).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Image.asset(
              AppAssets.iconBackRight,
              width: 16.r,
              height: 16.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ],
        ),
      ),
    );
  }
}
