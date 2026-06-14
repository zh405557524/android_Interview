part of 'index.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.inviteCode});

  final String? inviteCode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(
      AuthController(initialInviteCode: widget.inviteCode),
    );
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: CustomTheme.systemStyle,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF071306), Color(0xFF020403)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      CustomRouter.popOrMain(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => _AuthScrollBody(
                      controller: controller,
                      child: controller.isPhoneMode
                          ? PhoneLoginPanel(
                              authController: controller,
                              controller: controller.phone,
                            )
                          : OneTapLoginPanel(
                              authController: controller,
                              controller: controller.oneTap,
                            ),
                    ),
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

class _AuthScrollBody extends StatelessWidget {
  const _AuthScrollBody({required this.controller, required this.child});

  final AuthController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final agreementBottom = bottomInset > 0 ? 16.h : 58.h;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                child,
                Padding(
                  padding: EdgeInsets.only(top: 24.h, bottom: agreementBottom),
                  child: _AgreementRow(controller: controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.iconLogon,
      width: 88.w,
      height: 88.w,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final RxBool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppButton(
        label: label,
        loading: submitting.value,
        loadingLabel: '登录中...',
        onPressed: onPressed,
        width: 315.w,
        height: 56.h,
        borderRadius: 18.r,
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixIconAsset,
    this.suffix,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? prefixIconAsset;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55.h,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon: prefixIconAsset == null
              ? null
              : Padding(
                  padding: EdgeInsets.all(15.r),
                  child: Image.asset(
                    prefixIconAsset!,
                    width: 24.r,
                    height: 24.r,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
          suffixIcon: suffix,
          filled: true,
          fillColor: CustomTheme.primary.withValues(alpha: 0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: CustomTheme.primary),
          ),
        ),
      ),
    );
  }
}

class _LoginDivider extends StatelessWidget {
  const _LoginDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Image.asset(
            AppAssets.iconLine,
            height: 4.h,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11.sp,
            ),
          ),
        ),
        Expanded(
          child: Image.asset(
            AppAssets.iconLine,
            height: 4.h,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () =>
                controller.toggleAgreement(!controller.agreementAccepted.value),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: AppAgreementIcon(
                selected: controller.agreementAccepted.value,
              ),
            ),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AgreementText('我已阅读并同意'),
                _AgreementLink(
                  label: '《用户协议》',
                  onTap: () => context.pushNamed(
                    RouteName.webview,
                    queryParameters: <String, String>{'key': 'user-agreement'},
                  ),
                ),
                _AgreementText('和'),
                _AgreementLink(
                  label: '《隐私政策》',
                  onTap: () => context.pushNamed(
                    RouteName.webview,
                    queryParameters: <String, String>{'key': 'privacy-policy'},
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

class _AgreementText extends StatelessWidget {
  const _AgreementText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 12.sp,
      ),
    );
  }
}

class _AgreementLink extends StatelessWidget {
  const _AgreementLink({required this.label, required this.onTap});

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
