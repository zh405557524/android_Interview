part of 'index.dart';

class InviteLedgersPage extends StatefulWidget {
  const InviteLedgersPage({super.key});

  @override
  State<InviteLedgersPage> createState() => _InviteLedgersPageState();
}

class _InviteLedgersPageState extends State<InviteLedgersPage> {
  late final InviteLedgersController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteLedgersController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '收益明细',
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载收益明细...',
          errorMessage: controller.errorMessage.value ?? '收益明细加载失败',
          onRetry: controller.loadLedgers,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadLedgers),
          builder: (_) => RefreshIndicator(
            color: invitePrimary,
            backgroundColor: const Color(0xFF101C10),
            onRefresh: controller.loadLedgers,
            child: ListView(
              key: const ValueKey<String>('invite-ledgers'),
              padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 36.h),
              children: [
                if (controller.ledgers.isEmpty)
                  const InviteEmptyPanel(message: '暂无收益明细')
                else
                  ...controller.ledgers.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _LedgerCard(item: item),
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

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.item});

  final InviteEarningLedger item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 107.h),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: inviteCardDecoration(radius: 18.r),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _sourceLabel(item.sourceUserId),
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                    SizedBox(width: 8.w),
                    InviteMemberTag(text: item.relationLevel == 2 ? '间接' : '会员'),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  item.relationLevel == 2 ? '间接会员收益' : '开通会员名称',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.occurredAtText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: inviteTextMuted, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '+${inviteFormatYuan(item.amountCents)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String sourceUserId) {
    if (sourceUserId.trim().isEmpty) {
      return '受邀用户';
    }
    if (sourceUserId.length >= 4) {
      return '用户****${sourceUserId.substring(sourceUserId.length - 4)}';
    }
    return '用户 $sourceUserId';
  }
}
