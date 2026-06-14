part of 'index.dart';

class PaymentOrdersPage extends StatefulWidget {
  const PaymentOrdersPage({super.key});

  @override
  State<PaymentOrdersPage> createState() => _PaymentOrdersPageState();
}

class _PaymentOrdersPageState extends State<PaymentOrdersPage> with RouteAware {
  late final PaymentOrdersController controller;
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(PaymentOrdersController());
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
          '支付订单',
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
          child: RefreshIndicator(
            onRefresh: controller.refreshOrders,
            child: Obx(
              () => AppStateBuilder(
                state: controller.pageState,
                loadingMessage: '加载支付订单...',
                emptyMessage: '暂无支付订单',
                errorMessage: controller.errorMessage.value ?? '支付订单加载失败',
                onRetry: controller.loadOrders,
                builder: (_) => _PaymentOrdersList(controller: controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOrdersList extends StatelessWidget {
  const _PaymentOrdersList({required this.controller});

  final PaymentOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = controller.filteredOrders;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 30.h),
        children: [
          _PaymentOrderFilterBar(controller: controller),
          SizedBox(height: 14.h),
          if (orders.isEmpty)
            _FilteredOrdersEmpty(filter: controller.filter.value)
          else
            ...orders.map((order) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _PaymentOrderCard(order: order, controller: controller),
              );
            }),
        ],
      );
    });
  }
}

class _PaymentOrderFilterBar extends StatelessWidget {
  const _PaymentOrderFilterBar({required this.controller});

  final PaymentOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PaymentOrderFilter.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final item = PaymentOrderFilter.values[index];
          return Obx(() {
            final selected = controller.filter.value == item;
            return InkWell(
              onTap: () => controller.selectFilter(item),
              borderRadius: BorderRadius.circular(17.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? CustomTheme.primary
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17.r),
                  border: Border.all(
                    color: selected
                        ? CustomTheme.primary
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

class _PaymentOrderCard extends StatelessWidget {
  const _PaymentOrderCard({required this.order, required this.controller});

  final PaymentOrder order;
  final PaymentOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.productName.ifEmpty(order.purpose.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              _OrderStatusChip(status: order.status),
            ],
          ),
          SizedBox(height: 10.h),
          _OrderMetaLine(label: '订单号', value: order.orderNo.ifEmpty(order.id)),
          SizedBox(height: 6.h),
          _OrderMetaLine(label: '金额', value: order.amountText.ifEmpty('-')),
          SizedBox(height: 6.h),
          _OrderMetaLine(label: '时间', value: order.createdAtText.ifEmpty('-')),
          if (order.status == PaymentOrderStatus.pending) ...[
            SizedBox(height: 12.h),
            Obx(() {
              final processing =
                  controller.processingOrderId.value == order.identity;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _OrderActionButton(
                    text: processing ? '处理中' : '取消订单',
                    danger: true,
                    onPressed: processing
                        ? null
                        : () => controller.cancelOrder(context, order),
                  ),
                  _OrderActionButton(
                    text: processing ? '支付中' : '继续支付',
                    primary: true,
                    onPressed: processing
                        ? null
                        : () => controller.retryPayment(order),
                  ),
                ],
              );
            }),
          ] else ...[
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: Obx(() {
                final processing =
                    controller.processingOrderId.value == order.identity;
                return _OrderActionButton(
                  text: processing ? '处理中' : '删除订单',
                  danger: true,
                  onPressed: processing
                      ? null
                      : () => controller.deleteOrder(context, order),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({
    required this.text,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = primary
        ? Colors.black
        : danger
        ? const Color(0xFFFF8C8C)
        : Colors.white;
    final borderColor = danger
        ? const Color(0xFFFF7A7A).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.28);
    return SizedBox(
      width: 92.w,
      height: 34.h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? CustomTheme.primary
              : Colors.white.withValues(alpha: 0.06),
          disabledBackgroundColor: primary
              ? CustomTheme.primary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.04),
          foregroundColor: foreground,
          disabledForegroundColor: foreground.withValues(alpha: 0.45),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: onPressed == null
                  ? borderColor.withValues(alpha: 0.35)
                  : borderColor,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _OrderMetaLine extends StatelessWidget {
  const _OrderMetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48.w,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final PaymentOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilteredOrdersEmpty extends StatelessWidget {
  const _FilteredOrdersEmpty({required this.filter});

  final PaymentOrderFilter filter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360.h,
      child: Center(
        child: Text(
          '暂无${filter.label}订单',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

extension on PaymentOrderFilter {
  String get label {
    return switch (this) {
      PaymentOrderFilter.all => '全部',
      PaymentOrderFilter.membership => '会员',
      PaymentOrderFilter.points => '积分',
    };
  }
}

extension on PaymentPurpose {
  String get label {
    return switch (this) {
      PaymentPurpose.membership => '会员订单',
      PaymentPurpose.points => '积分订单',
    };
  }
}

extension on PaymentOrderStatus {
  String get label {
    return switch (this) {
      PaymentOrderStatus.pending => '待支付',
      PaymentOrderStatus.paid => '已支付',
      PaymentOrderStatus.canceled => '已取消',
      PaymentOrderStatus.failed => '已关闭',
    };
  }

  Color get color {
    return switch (this) {
      PaymentOrderStatus.pending => CustomTheme.primary,
      PaymentOrderStatus.paid => const Color(0xFF56F08A),
      PaymentOrderStatus.canceled => Colors.white54,
      PaymentOrderStatus.failed => const Color(0xFFFF7A7A),
    };
  }
}
