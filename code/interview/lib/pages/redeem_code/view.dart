part of 'index.dart';

class RedeemCodePage extends StatefulWidget {
  const RedeemCodePage({super.key});

  @override
  State<RedeemCodePage> createState() => _RedeemCodePageState();
}

class _RedeemCodePageState extends State<RedeemCodePage> {
  late final RedeemCodeController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(RedeemCodeController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '兑换码',
      child: ListView(
        key: const ValueKey<String>('redeem-code-page'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(15.w, 50.h, 15.w, 36.h),
        children: [
          InviteTextInput(
            controller: controller.codeController,
            hintText: '请输入兑换码',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => controller.result.value = null,
          ),
          SizedBox(height: 26.h),
          Obx(
            () => InviteGradientButton(
              label: controller.submitting.value ? '兑换中...' : '立即兑换',
              onPressed: controller.submitting.value ? null : controller.redeem,
            ),
          ),
          Obx(() {
            final result = controller.result.value;
            if (result == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: _RedeemResultCard(result: result),
            );
          }),
          SizedBox(height: 28.h),
          Text(
            '兑换须知',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '1.兑换成功后权益立即生效;\n'
            '2.同一批次兑换码只发放一种权益，积分或会员天数以实际结果为准;\n'
            '3.兑换码一经使用，不予更改，请认真保管您的兑换码;',
            style: TextStyle(
              color: inviteTextMuted,
              fontSize: 14.sp,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemResultCard extends StatelessWidget {
  const _RedeemResultCard({required this.result});

  final RedeemCodeResult result;

  @override
  Widget build(BuildContext context) {
    final expireAt = result.membershipExpiredAt;
    return InvitePanelCard(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: invitePrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17.r),
            ),
            child: Icon(
              result.isPoints
                  ? Icons.control_point_duplicate_rounded
                  : Icons.workspace_premium_rounded,
              color: invitePrimary,
              size: 20.r,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.rewardText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (result.isPoints && result.pointsBalance != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '当前积分 ${result.pointsBalance}',
                    style: TextStyle(color: inviteTextMuted, fontSize: 12.sp),
                  ),
                ],
                if (expireAt != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '有效期至 ${_formatDate(expireAt)}',
                    style: TextStyle(color: inviteTextMuted, fontSize: 12.sp),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }
}
