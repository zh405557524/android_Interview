part of 'index.dart';

class PointsLedgerPage extends StatefulWidget {
  const PointsLedgerPage({super.key});

  @override
  State<PointsLedgerPage> createState() => _PointsLedgerPageState();
}

class _PointsLedgerPageState extends State<PointsLedgerPage> with RouteAware {
  late final PointsLedgerController controller;
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(PointsLedgerController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        CustomRouter.observer.unsubscribe(this);
      }
      _route = route;
      CustomRouter.observer.subscribe(this, route);
    }
  }

  @override
  void didPush() {
    _refreshOnEnter();
  }

  @override
  void didPopNext() {
    _refreshOnEnter();
  }

  @override
  void dispose() {
    CustomRouter.observer.unsubscribe(this);
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  void _refreshOnEnter() {
    unawaited(controller.refreshOnEnter());
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
          '积分详情',
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
          child: Obx(
            () => AppStateBuilder(
              state: controller.pageState,
              loadingMessage: '加载积分详情...',
              emptyMessage: '暂无积分流水',
              errorMessage: controller.errorMessage.value ?? '积分详情加载失败',
              onRetry: controller.loadLedger,
              builder: (_) => ListView.separated(
                padding: EdgeInsets.fromLTRB(15.w, 6.h, 15.w, 30.h),
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  return _LedgerRow(item: controller.items[index]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.item});

  final PointsLedgerItem item;

  @override
  Widget build(BuildContext context) {
    final income = item.direction == PointDirection.income || item.amount > 0;
    final amountText = income
        ? '+${item.amount.abs()}'
        : '-${item.amount.abs()}';
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
                SizedBox(height: 5.h),
                Text(
                  item.dateText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              color: income ? CustomTheme.primary : Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
