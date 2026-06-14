part of 'index.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  late final SettingsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SettingsController>()) {
      controller = Get.find<SettingsController>();
      _ownsController = false;
    } else {
      controller = Get.put(SettingsController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      deleteControllerIfCurrent(controller);
    }
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
          '账号与安全',
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 30.h),
            child: Column(
              children: [
                const Spacer(),
                Obx(
                  () => _DeleteAccountFooterButton(
                    disabled: controller.submitting.value,
                    onTap: () async {
                      final confirmed = await _showDeleteAccountSheet(context);
                      if (confirmed != true || !context.mounted) {
                        return;
                      }
                      final success = await controller.requestDeleteAccount();
                      if (!success || !context.mounted) {
                        return;
                      }
                      if (Get.isRegistered<MainController>()) {
                        Get.find<MainController>().showHomeTab();
                      }
                      context.goNamed(RouteName.main);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.76),
    builder: (sheetContext) {
      return _DeleteAccountConfirmSheet(
        onCancel: () => Navigator.pop(sheetContext, false),
        onConfirm: () => Navigator.pop(sheetContext, true),
      );
    },
  );
}

class _DeleteAccountConfirmSheet extends StatelessWidget {
  const _DeleteAccountConfirmSheet({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B100C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                '注销账号',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                '注销后账号资料、历史记录等将无法恢复。\n请确认你已经了解相关影响。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF9DA3A0),
                  fontSize: 14.sp,
                  height: 1.65,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 49.h,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: const Text('我再想想'),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 49.h,
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomTheme.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  child: const Text('确认注销账号'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
