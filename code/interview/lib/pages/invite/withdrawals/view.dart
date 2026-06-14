part of 'index.dart';

class InviteWithdrawalRecordsPage extends StatefulWidget {
  const InviteWithdrawalRecordsPage({super.key});

  @override
  State<InviteWithdrawalRecordsPage> createState() =>
      _InviteWithdrawalRecordsPageState();
}

class _InviteWithdrawalRecordsPageState
    extends State<InviteWithdrawalRecordsPage> {
  late final InviteWithdrawalRecordsController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteWithdrawalRecordsController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '提现记录',
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载提现记录...',
          errorMessage: controller.errorMessage.value ?? '提现记录加载失败',
          onRetry: controller.loadWithdrawals,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadWithdrawals),
          builder: (_) => RefreshIndicator(
            color: invitePrimary,
            backgroundColor: const Color(0xFF101C10),
            onRefresh: controller.loadWithdrawals,
            child: _WithdrawalRecordsContent(
              totalCents:
                  controller.earningSummary.value?.totalEarningsCents ?? 0,
              withdrawals: controller.withdrawals,
            ),
          ),
        ),
      ),
    );
  }
}

class _WithdrawalRecordsContent extends StatelessWidget {
  const _WithdrawalRecordsContent({
    required this.totalCents,
    required this.withdrawals,
  });

  final int totalCents;
  final List<InviteWithdrawal> withdrawals;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('invite-withdrawals'),
      padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 36.h),
      children: [
        _TotalIncomeCard(totalCents: totalCents),
        SizedBox(height: 20.h),
        if (withdrawals.isEmpty)
          const InviteEmptyPanel(message: '暂无提现记录')
        else
          ...withdrawals.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _WithdrawalRecordCard(item: item),
            ),
          ),
      ],
    );
  }
}

class _TotalIncomeCard extends StatelessWidget {
  const _TotalIncomeCard({required this.totalCents});

  final int totalCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 127.h,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF233209), Color(0xFF061005), Color(0xFF1F2C09)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  inviteFormatYuan(totalCents),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '累计收益  (元)',
                  style: TextStyle(color: inviteTextMuted, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          Container(
            width: 62.r,
            height: 62.r,
            decoration: BoxDecoration(
              color: invitePrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings_rounded,
              color: invitePrimary,
              size: 34.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalRecordCard extends StatelessWidget {
  const _WithdrawalRecordCard({required this.item});

  final InviteWithdrawal item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 79.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 12.h),
      decoration: inviteCardDecoration(radius: 12.r),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '余额提现',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7.h),
                Text(
                  item.createdAtText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: inviteTextMuted, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '-${inviteFormatYuan(item.amountCents)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _withdrawalStatus(item),
                style: TextStyle(
                  color: _withdrawalStatusColor(item),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _withdrawalStatus(InviteWithdrawal item) {
    return switch (item.status) {
      'PAID' => '提现成功',
      'PAY_FAILED' => '提现失败',
      'APPROVED' || 'PENDING_REVIEW' => '提现中',
      'REJECTED' => '已驳回',
      _ => item.statusText,
    };
  }

  Color _withdrawalStatusColor(InviteWithdrawal item) {
    return switch (item.status) {
      'PAID' => invitePrimary,
      'PAY_FAILED' || 'REJECTED' => const Color(0xFFFF2C2C),
      _ => const Color(0xFFFFC400),
    };
  }
}
