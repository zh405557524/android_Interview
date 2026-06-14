part of 'index.dart';

final class PointsRechargeController extends GetxController {
  final UserStore userStore = Get.find<UserStore>();

  static const int _paymentPollAttempts = 5;
  static const Duration _paymentPollDelay = Duration(milliseconds: 1500);

  final RxBool loading = false.obs;
  final RxBool submitting = false.obs;
  final RxBool agreementAccepted = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<PointsPackage> packages = <PointsPackage>[].obs;
  final RxnString selectedPackageId = RxnString();
  final Rx<PaymentChannel> channel = PaymentChannel.alipay.obs;

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
    if (packages.isEmpty) {
      return ViewState.empty;
    }
    return submitting.value ? ViewState.submitting : ViewState.success;
  }

  @override
  void onInit() {
    super.onInit();
    loadPackages();
  }

  PointsPackage? get selectedPackage {
    final selectedId = selectedPackageId.value;
    if (selectedId == null) {
      return null;
    }
    for (final item in packages) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  Future<void> loadPackages() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _pointsPackages();
      packages.assignAll(result);
      if (result.isEmpty) {
        selectedPackageId.value = null;
      } else if (!_containsPackage(result, selectedPackageId.value)) {
        selectedPackageId.value = result.first.id;
      }
    } on ApiException catch (error, stackTrace) {
      AppLogger.error(
        '[Payment][Points] load packages failed',
        error,
        stackTrace,
      );
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  void selectPackage(String id) {
    if (!_containsPackage(packages, id)) {
      AppLogger.error('[Payment][Points] selected package not found: $id');
      return;
    }
    if (selectedPackageId.value == id) {
      return;
    }
    selectedPackageId.value = id;
  }

  void selectChannel(PaymentChannel value) {
    channel.value = value;
  }

  void toggleAgreement(bool value) {
    agreementAccepted.value = value;
  }

  Future<void> submit(BuildContext context) async {
    if (submitting.value) {
      return;
    }
    final package = selectedPackage;
    if (package == null) {
      CustomToast.text('请选择积分套餐');
      return;
    }
    final agreementError = AppValidators.agreementError(
      agreementAccepted.value,
      '请先同意充值协议',
    );
    if (agreementError != null) {
      CustomToast.text(agreementError);
      return;
    }

    submitting.value = true;
    try {
      final order = await PaymentAPI.createPointsOrder(
        packageId: package.id,
        channel: channel.value,
      );
      final sdkResult = await _paymentGateway.pay(order);
      if (sdkResult.isCanceled) {
        CustomToast.text('支付已取消');
        return;
      }
      if (sdkResult.isFailed) {
        CustomToast.error(
          sdkResult.message.ifEmpty('支付失败，请稍后重试'),
          error: sdkResult.raw,
          tag: '[Payment][Points]',
        );
        return;
      }

      final latestOrder = await _pollPaymentOrder(order);
      if (!context.mounted) {
        return;
      }
      await _handlePaymentOrder(context, latestOrder);
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        error.userMessage,
        error: error,
        stackTrace: stackTrace,
        tag: '[Payment][Points]',
      );
    } finally {
      submitting.value = false;
    }
  }

  Future<void> _handlePaymentOrder(
    BuildContext context,
    PaymentOrder order,
  ) async {
    switch (order.status) {
      case PaymentOrderStatus.paid:
        await PaymentCompletion.refreshUserAndClosePage(
          context: context,
          userStore: userStore,
          successMessage: '积分已到账',
          tag: '[Payment][Points]',
        );
      case PaymentOrderStatus.pending:
        CustomToast.text('支付处理中，请稍后查看订单状态');
      case PaymentOrderStatus.canceled:
        CustomToast.text('支付已取消');
      case PaymentOrderStatus.failed:
        CustomToast.text('订单已关闭，请重新下单');
    }
  }

  Future<PaymentOrder> _pollPaymentOrder(PaymentOrder order) async {
    final orderId = order.id.isNotEmpty ? order.id : order.orderNo;
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

  Future<List<PointsPackage>> _pointsPackages() {
    return PaymentAPI.pointsPackages();
  }

  bool _containsPackage(Iterable<PointsPackage> items, String? id) {
    if (id == null || id.isEmpty) {
      return false;
    }
    for (final item in items) {
      if (item.id == id) {
        return true;
      }
    }
    return false;
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
