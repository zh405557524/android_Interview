part of '../index.dart';

class OneTapLoginPanel extends StatelessWidget {
  const OneTapLoginPanel({
    required this.authController,
    required this.controller,
    super.key,
  });

  final AuthController authController;
  final OneTapLoginController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 60.h),
        const _BrandMark(),
        SizedBox(height: 92.h),
        Obx(
          () => Text(
            controller.phoneLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '运营商提供认证服务',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 28.h),
        _PrimaryLoginButton(
          label: '一键登录',
          submitting: controller.submitting,
          onPressed: () async {
            if (!await controller.submit() || !context.mounted) {
              return;
            }
            if (Get.isRegistered<AppUpdateService>()) {
              await Get.find<AppUpdateService>().checkAfterLogin(context);
            }
            if (!context.mounted) {
              return;
            }
            CustomRouter.popOrMain(context);
          },
        ),
        SizedBox(height: 34.h),
        _LoginDivider(label: '其他方式登录'),
        SizedBox(height: 24.h),
        TextButton(
          onPressed: authController.showPhoneMode,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '切换账号',
                style: TextStyle(color: CustomTheme.primary, fontSize: 14.sp),
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
      ],
    );
  }
}
