part of 'index.dart';

class InviteWithdrawalPage extends StatefulWidget {
  const InviteWithdrawalPage({super.key});

  @override
  State<InviteWithdrawalPage> createState() => _InviteWithdrawalPageState();
}

class _InviteWithdrawalPageState extends State<InviteWithdrawalPage> {
  late final InviteWithdrawalController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteWithdrawalController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '提现',
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载提现信息...',
          errorMessage: controller.errorMessage.value ?? '提现信息加载失败',
          onRetry: controller.loadWithdrawal,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadWithdrawal),
          builder: (_) => Obx(
            () => _WithdrawalContent(
              amountController: controller.withdrawAmountController,
              accountLabel: _maskedAccount(
                controller.withdrawAccountDisplay.value,
              ),
              withdrawableCents: controller.withdrawableCents,
              agreementAccepted: controller.withdrawalAgreementAccepted.value,
              submitting: controller.withdrawing.value,
              onAccountTap: () async {
                await showInviteWithdrawAccountSheet(
                  context,
                  accountController: controller.withdrawAccountController,
                  nameController: controller.withdrawNameController,
                );
                controller.syncWithdrawAccountDisplay();
              },
              onFillAll: controller.fillAllWithdrawable,
              onToggleAgreement: controller.toggleAgreementAccepted,
              onSubmit: controller.createWithdrawal,
            ),
          ),
        ),
      ),
    );
  }

  String _maskedAccount(String value) {
    if (value.length <= 4) {
      return '支付宝';
    }
    return '****${value.substring(value.length - 4)}';
  }
}

class _WithdrawalContent extends StatelessWidget {
  const _WithdrawalContent({
    required this.amountController,
    required this.accountLabel,
    required this.withdrawableCents,
    required this.agreementAccepted,
    required this.submitting,
    required this.onAccountTap,
    required this.onFillAll,
    required this.onToggleAgreement,
    required this.onSubmit,
  });

  final TextEditingController amountController;
  final String accountLabel;
  final int withdrawableCents;
  final bool agreementAccepted;
  final bool submitting;
  final VoidCallback onAccountTap;
  final VoidCallback onFillAll;
  final VoidCallback onToggleAgreement;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('invite-withdrawal'),
      padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 36.h),
      children: [
        _AccountMethodRow(accountLabel: accountLabel, onTap: onAccountTap),
        SizedBox(height: 16.h),
        InvitePanelCard(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '提现金额',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '¥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      cursorColor: invitePrimary,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '输入提现金额',
                        hintStyle: TextStyle(
                          color: inviteTextMuted,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '最多可提现 ¥${inviteFormatYuan(withdrawableCents)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: inviteTextMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onFillAll,
                    child: Text(
                      '全部提现',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              InviteGradientButton(
                label: submitting ? '提交中...' : '立即提现',
                onPressed: submitting ? null : onSubmit,
              ),
              SizedBox(height: 12.h),
              InkWell(
                onTap: onToggleAgreement,
                borderRadius: BorderRadius.circular(8.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      agreementAccepted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: agreementAccepted ? invitePrimary : Colors.white70,
                      size: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        '我已阅读并同意《灵活就业合作伙伴协议》',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: inviteTextMuted,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountMethodRow extends StatelessWidget {
  const _AccountMethodRow({required this.accountLabel, required this.onTap});

  final String accountLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: inviteCardDecoration(radius: 18.r),
        child: Row(
          children: [
            Text(
              '提现至',
              style: TextStyle(color: inviteTextMuted, fontSize: 16.sp),
            ),
            const Spacer(),
            Image.asset(
              AppAssets.iconZhifubao,
              width: 20.r,
              height: 20.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(width: 6.w),
            Text(
              accountLabel,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22.r),
          ],
        ),
      ),
    );
  }
}
