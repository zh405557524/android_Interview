part of 'index.dart';

class PointsRechargePage extends StatefulWidget {
  const PointsRechargePage({super.key});

  @override
  State<PointsRechargePage> createState() => _PointsRechargePageState();
}

class _PointsRechargePageState extends State<PointsRechargePage> {
  late final PointsRechargeController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(PointsRechargeController());
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
          '积分充值',
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
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Image.asset(
                AppAssets.iconRechargeBg,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Obx(
                  () => AppStateBuilder(
                    state: controller.pageState,
                    loadingMessage: '加载积分套餐...',
                    emptyMessage: '暂无可购买积分套餐',
                    errorMessage: controller.errorMessage.value ?? '积分套餐加载失败',
                    onRetry: controller.loadPackages,
                    builder: (_) => Obx(
                      () => ListView(
                        padding: EdgeInsets.fromLTRB(15.w, 222.h, 15.w, 130.h),
                        children: [
                          _PointsPackageGrid(
                            packages: controller.packages,
                            selectedPackageId:
                                controller.selectedPackageId.value,
                            onSelectPackage: controller.selectPackage,
                          ),
                          SizedBox(height: 22.h),
                          Text(
                            '选择支付方式',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          _PaymentChannelRow(
                            controller: controller,
                            channel: PaymentChannel.alipay,
                            label: '支付宝',
                            iconAsset: AppAssets.iconZhifubao,
                          ),
                          _RechargeAgreement(controller: controller),
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
              child: SafeArea(
                top: false,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsPackageGrid extends StatelessWidget {
  const _PointsPackageGrid({
    required this.packages,
    required this.selectedPackageId,
    required this.onSelectPackage,
  });

  final List<PointsPackage> packages;
  final String? selectedPackageId;
  final ValueChanged<String> onSelectPackage;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 110 / 85,
      ),
      itemBuilder: (context, index) {
        final package = packages[index];
        final selected = selectedPackageId == package.id;
        return _PointsPackageCard(
          key: ValueKey<String>('points-package-${package.id}-$selected'),
          package: package,
          selected: selected,
          onTap: () => onSelectPackage(package.id),
        );
      },
    );
  }
}

class _PointsPackageCard extends StatelessWidget {
  const _PointsPackageCard({
    required this.package,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final PointsPackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? CustomTheme.primary.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? CustomTheme.primary : const Color(0xFF2E4824),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.iconIntegral,
                  width: 23.r,
                  height: 23.r,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    '${package.points}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              package.priceText,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChannelRow extends StatelessWidget {
  const _PaymentChannelRow({
    required this.controller,
    required this.channel,
    required this.label,
    required this.iconAsset,
  });

  final PointsRechargeController controller;
  final PaymentChannel channel;
  final String label;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.channel.value == channel;
      return InkWell(
        onTap: () => controller.selectChannel(channel),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: 22.r,
                height: 22.r,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSelectionIcon(selected: selected),
            ],
          ),
        ),
      );
    });
  }
}

class _RechargeAgreement extends StatelessWidget {
  const _RechargeAgreement({required this.controller});

  final PointsRechargeController controller;

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
            child: Text(
              '我已阅读并同意积分充值协议',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
