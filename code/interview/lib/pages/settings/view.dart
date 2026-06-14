part of 'index.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(SettingsController());
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
          '更多设置',
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
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 30.h),
            children: [
              _SettingsRow(
                icon: Icons.description_outlined,
                title: '用户协议',
                onTap: () => context.pushNamed(
                  RouteName.webview,
                  queryParameters: <String, String>{'key': 'user-agreement'},
                ),
              ),
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                onTap: () => context.pushNamed(
                  RouteName.webview,
                  queryParameters: <String, String>{'key': 'privacy-policy'},
                ),
              ),
              SizedBox(height: 14.h),
              Obx(
                () => _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: '当前版本',
                  trailing: controller.versionText.value,
                ),
              ),
              Obx(
                () => _SettingsRow(
                  icon: Icons.system_update_alt_rounded,
                  title: '检查更新',
                  trailing: controller.checkingUpdate.value ? '检查中' : null,
                  onTap: controller.checkingUpdate.value
                      ? null
                      : () => controller.checkUpdate(context),
                ),
              ),
              Obx(
                () => _SettingsRow(
                  icon: Icons.cleaning_services_outlined,
                  title: '清理缓存',
                  trailing: controller.clearingCache.value ? '清理中' : '0 MB',
                  onTap: controller.clearCache,
                ),
              ),
              SizedBox(height: 14.h),
              _SettingsRow(
                icon: Icons.security_outlined,
                title: '账号与安全',
                onTap: () => context.pushNamed(RouteName.accountSecurity),
              ),
              SizedBox(height: 74.h),
              Obx(
                () => _SettingsDangerRow(
                  title: controller.submitting.value ? '处理中' : '退出登录',
                  disabled: controller.submitting.value,
                  onTap: () async {
                    final confirmed = await AppConfirmDialog.show(
                      context,
                      title: '退出登录',
                      message: '确定退出当前账号吗？',
                    );
                    if (confirmed == true) {
                      final success = await controller.logout();
                      if (!success || !context.mounted) {
                        return;
                      }
                      if (Get.isRegistered<MainController>()) {
                        Get.find<MainController>().showHomeTab();
                      }
                      CustomRouter.popOrMain(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 60.h,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: CustomTheme.primary, size: 22.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(color: Colors.white60, fontSize: 13.sp),
              )
            else
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

class _SettingsDangerRow extends StatelessWidget {
  const _SettingsDangerRow({
    required this.title,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      width: double.infinity,
      child: TextButton(
        onPressed: disabled ? null : onTap,
        style: TextButton.styleFrom(foregroundColor: CustomTheme.danger),
        child: Text(title),
      ),
    );
  }
}

class _DeleteAccountFooterButton extends StatelessWidget {
  const _DeleteAccountFooterButton({
    required this.onTap,
    this.disabled = false,
  });

  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = CustomTheme.danger.withValues(alpha: disabled ? 0.32 : 0.72);
    return Center(
      child: TextButton(
        onPressed: disabled ? null : onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color,
          minimumSize: Size(88.w, 34.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
        ),
        child: const Text('注销账号'),
      ),
    );
  }
}
