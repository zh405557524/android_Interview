part of 'index.dart';

enum PaymentOrderFilter { all, membership, points }

final class PaymentOrdersController extends GetxController {
  final UserStore userStore = Get.find<UserStore>();

  static const int _paymentPollAttempts = 5;
  static const Duration _paymentPollDelay = Duration(milliseconds: 1500);

  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<PaymentOrder> orders = <PaymentOrder>[].obs;
  final Rx<PaymentOrderFilter> filter = PaymentOrderFilter.all.obs;
  final RxnString processingOrderId = RxnString();

  final Set<String> _locallyDeletedOrderIds = <String>{};

  PaymentGatewayService get _paymentGateway =>
      Get.isRegistered<PaymentGatewayService>()
      ? Get.find<PaymentGatewayService>()
      : Get.put(PaymentGatewayService());

  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    if (orders.isEmpty) {
      return ViewState.empty;
    }
    return ViewState.success;
  }

  List<PaymentOrder> get filteredOrders {
    return switch (filter.value) {
      PaymentOrderFilter.all => orders.toList(growable: false),
      PaymentOrderFilter.membership =>
        orders
            .where((item) => item.purpose == PaymentPurpose.membership)
            .toList(growable: false),
      PaymentOrderFilter.points =>
        orders
            .where((item) => item.purpose == PaymentPurpose.points)
            .toList(growable: false),
    };
  }

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!silent) {
      loading.value = true;
    }
    errorMessage.value = null;
    try {
      final result = await PaymentAPI.orders(pageNo: 1, pageSize: 50);
      orders.assignAll(result.items.where((item) => !_isLocallyDeleted(item)));
    } on ApiException catch (error, stackTrace) {
      AppLogger.error(
        '[Payment][Orders] load orders failed silent=$silent',
        error,
        stackTrace,
      );
      if (!silent) {
        errorMessage.value = error.userMessage;
      } else {
        CustomToast.error(
          error.userMessage,
          error: error,
          stackTrace: stackTrace,
          tag: '[Payment][Orders]',
        );
      }
    } finally {
      if (!silent) {
        loading.value = false;
      }
    }
  }

  Future<void> refreshOrders() {
    return loadOrders();
  }

  Future<void> refreshOnEnter() {
    if (loading.value || processingOrderId.value != null) {
      return Future<void>.value();
    }
    return loadOrders(silent: orders.isNotEmpty);
  }

  void selectFilter(PaymentOrderFilter value) {
    filter.value = value;
  }

  Future<void> retryPayment(PaymentOrder order) async {
    if (processingOrderId.value != null) {
      return;
    }
    if (order.status != PaymentOrderStatus.pending) {
      CustomToast.text(_settledOrderMessage(order.status));
      return;
    }
    final orderId = order.identity;
    if (orderId.isEmpty) {
      CustomToast.text('订单号为空，无法继续支付');
      return;
    }

    processingOrderId.value = orderId;
    try {
      CustomToast.loading('加载支付参数...');
      late final PaymentOrder payableOrder;
      try {
        payableOrder = await PaymentAPI.orderDetail(orderId);
      } finally {
        CustomToast.dismiss();
      }
      _replaceOrder(payableOrder);
      if (payableOrder.status != PaymentOrderStatus.pending) {
        CustomToast.text(_settledOrderMessage(payableOrder.status));
        await loadOrders(silent: true);
        return;
      }
      if (payableOrder.orderInfo.trim().isEmpty) {
        CustomToast.text('订单支付参数已失效，请重新下单');
        await loadOrders(silent: true);
        return;
      }

      final sdkResult = await _paymentGateway.pay(payableOrder);
      if (sdkResult.isCanceled) {
        CustomToast.text('支付已取消');
        await loadOrders(silent: true);
        return;
      }
      if (sdkResult.isFailed) {
        CustomToast.error(
          sdkResult.message.ifEmpty('支付失败，请稍后重试'),
          error: sdkResult.raw,
          tag: '[Payment][Orders]',
        );
        await loadOrders(silent: true);
        return;
      }

      final latestOrder = await _pollPaymentOrder(payableOrder);
      _replaceOrder(latestOrder);
      await _handlePaymentOrder(latestOrder);
      await loadOrders(silent: true);
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        error.userMessage,
        error: error,
        stackTrace: stackTrace,
        tag: '[Payment][Orders]',
      );
    } finally {
      processingOrderId.value = null;
    }
  }

  Future<void> cancelOrder(BuildContext context, PaymentOrder order) async {
    if (processingOrderId.value != null) {
      return;
    }
    if (order.status != PaymentOrderStatus.pending) {
      CustomToast.text(_settledOrderMessage(order.status));
      return;
    }
    final orderId = order.identity;
    if (orderId.isEmpty) {
      CustomToast.error(
        '订单号为空，无法取消订单',
        error: order.toJson(),
        tag: '[Payment][Orders]',
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context,
      title: '取消订单',
      message: '取消后该订单将无法继续支付，确认取消吗？',
      confirmText: '确认取消',
    );
    if (confirmed != true) {
      return;
    }

    processingOrderId.value = orderId;
    try {
      await PaymentAPI.cancelOrders(<String>[orderId]);
      _replaceOrder(order.copyWith(status: PaymentOrderStatus.canceled));
      CustomToast.text('订单已取消');
      await loadOrders(silent: true);
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        error.userMessage,
        error: error,
        stackTrace: stackTrace,
        tag: '[Payment][Orders]',
      );
    } finally {
      processingOrderId.value = null;
    }
  }

  Future<void> deleteOrder(BuildContext context, PaymentOrder order) async {
    if (processingOrderId.value != null) {
      return;
    }
    if (order.status == PaymentOrderStatus.pending) {
      CustomToast.text('待支付订单请先取消后再删除');
      return;
    }
    final orderId = order.identity;
    if (orderId.isEmpty) {
      CustomToast.error(
        '订单号为空，无法删除订单',
        error: order.toJson(),
        tag: '[Payment][Orders]',
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context,
      title: '删除订单',
      message: '删除后该订单将不再展示，确认删除吗？',
      confirmText: '确认删除',
    );
    if (confirmed != true) {
      return;
    }

    processingOrderId.value = orderId;
    try {
      await PaymentAPI.deleteOrders(<String>[orderId]);
      _rememberDeletedOrder(order);
      _removeOrder(order);
      CustomToast.text('订单已删除');
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        error.userMessage,
        error: error,
        stackTrace: stackTrace,
        tag: '[Payment][Orders]',
      );
    } finally {
      processingOrderId.value = null;
    }
  }

  Future<PaymentOrder> _pollPaymentOrder(PaymentOrder order) async {
    final orderId = order.identity;
    if (orderId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.paymentFailed,
        message: '订单号为空，无法确认支付状态',
      );
    }
    var latest = order;
    for (var index = 0; index < _paymentPollAttempts; index += 1) {
      latest = await PaymentAPI.orderDetail(orderId);
      if (latest.status != PaymentOrderStatus.pending) {
        return latest;
      }
      if (index < _paymentPollAttempts - 1) {
        await Future<void>.delayed(_paymentPollDelay);
      }
    }
    return latest;
  }

  Future<void> _handlePaymentOrder(PaymentOrder order) async {
    switch (order.status) {
      case PaymentOrderStatus.paid:
        await PaymentCompletion.refreshUserAndOpenAccount(
          userStore: userStore,
          successMessage: order.purpose == PaymentPurpose.membership
              ? '会员已开通'
              : '积分已到账',
          tag: '[Payment][Orders]',
        );
      case PaymentOrderStatus.pending:
        CustomToast.text('支付处理中，请稍后查看订单状态');
      case PaymentOrderStatus.canceled:
        CustomToast.text('支付已取消');
      case PaymentOrderStatus.failed:
        CustomToast.text('订单已关闭，请重新下单');
    }
  }

  void _replaceOrder(PaymentOrder order) {
    final index = orders.indexWhere((item) {
      return item.identity == order.identity ||
          (item.orderNo.isNotEmpty && item.orderNo == order.orderNo);
    });
    if (index < 0) {
      orders.insert(0, order);
      return;
    }
    orders[index] = order;
  }

  void _removeOrder(PaymentOrder order) {
    orders.removeWhere((item) {
      return item.identity == order.identity ||
          (item.orderNo.isNotEmpty && item.orderNo == order.orderNo);
    });
  }

  void _rememberDeletedOrder(PaymentOrder order) {
    for (final key in _orderKeys(order)) {
      _locallyDeletedOrderIds.add(key);
    }
  }

  bool _isLocallyDeleted(PaymentOrder order) {
    return _orderKeys(order).any(_locallyDeletedOrderIds.contains);
  }

  Iterable<String> _orderKeys(PaymentOrder order) sync* {
    for (final value in <String>[order.id, order.orderNo, order.identity]) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        yield normalized;
      }
    }
  }

  String _settledOrderMessage(PaymentOrderStatus status) {
    return switch (status) {
      PaymentOrderStatus.pending => '订单待支付',
      PaymentOrderStatus.paid => '订单已支付',
      PaymentOrderStatus.canceled => '支付已取消',
      PaymentOrderStatus.failed => '订单已关闭，请重新下单',
    };
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
