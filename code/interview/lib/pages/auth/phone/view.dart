part of '../index.dart';

class PhoneLoginPanel extends StatelessWidget {
  const PhoneLoginPanel({
    required this.authController,
    required this.controller,
    super.key,
  });

  final AuthController authController;
  final PhoneLoginController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 60.h),
        const _BrandMark(),
        SizedBox(height: 142.h),
        _LoginInput(
          controller: controller.phoneController,
          hintText: '请输入手机号',
          keyboardType: TextInputType.phone,
          prefixIconAsset: AppAssets.iconPhone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppValidators.phoneLength),
          ],
        ),
        SizedBox(height: 15.h),
        Obx(
          () => _LoginInput(
            controller: controller.codeController,
            hintText: '请输入验证码',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(AppValidators.smsCodeMaxLength),
            ],
            suffix: TextButton(
              onPressed: controller.canSendCode ? controller.sendCode : null,
              child: Text(
                controller.secondsLeft.value == 0
                    ? '获取验证码'
                    : '${controller.secondsLeft.value}s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: controller.canSendCode
                      ? CustomTheme.primary
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 35.h),
        _PrimaryLoginButton(
          label: '登录',
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
        Obx(
          () => authController.oneTapAvailable.value
              ? TextButton(
                  onPressed: authController.showOneTapMode,
                  child: Text(
                    '返回一键登录',
                    style: TextStyle(
                      color: CustomTheme.primary,
                      fontSize: 13.sp,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
