part of 'index.dart';

final class MembershipController extends GetxController {
  final UserStore userStore = Get.find<UserStore>();

  static const int _paymentPollAttempts = 5;
  static const Duration _paymentPollDelay = Duration(milliseconds: 1500);

  final RxBool loading = false.obs;
  final RxBool submitting = false.obs;
  final RxBool agreementAccepted = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<MembershipPlan> plans = <MembershipPlan>[].obs;
  final RxnString selectedPlanId = RxnString();

  final List<String> benefits = const <String>[
    '购买积分打7折',
    '高阶模型和更多功能',
    '视频更高清更流畅',
    '会员专属配音免费使用',
    '免费创建形象不限次数',
  ];

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
    if (plans.isEmpty) {
      return ViewState.empty;
    }
    return submitting.value ? ViewState.submitting : ViewState.success;
  }

  @override
  void onInit() {
    super.onInit();
    loadPlans();
  }

  MembershipPlan? get selectedPlan {
    for (final item in plans) {
      if (item.id == selectedPlanId.value) {
        return item;
      }
    }
    return plans.isEmpty ? null : plans.first;
  }

  Future<void> loadPlans() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _membershipPlans();
      plans.assignAll(result);
      if (result.isNotEmpty && selectedPlanId.value == null) {
        selectedPlanId.value = result.first.id;
      }
    } on ApiException catch (error, stackTrace) {
      AppLogger.error(
        '[Payment][Membership] load plans failed',
        error,
        stackTrace,
      );
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  void selectPlan(String id) {
    selectedPlanId.value = id;
  }

  void toggleAgreement(bool value) {
    agreementAccepted.value = value;
  }

  Future<void> submit(BuildContext context) async {
    if (submitting.value) {
      return;
    }
    final plan = selectedPlan;
    if (plan == null) {
      CustomToast.text('请选择会员套餐');
      return;
    }
    final agreementError = AppValidators.agreementError(
      agreementAccepted.value,
      '请先同意会员服务协议',
    );
    if (agreementError != null) {
      CustomToast.text(agreementError);
      return;
    }

    submitting.value = true;
    try {
      final order = await PaymentAPI.createMembershipOrder(
        planId: plan.id,
        channel: PaymentChannel.alipay,
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
          tag: '[Payment][Membership]',
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
        tag: '[Payment][Membership]',
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
          successMessage: '会员已开通',
          tag: '[Payment][Membership]',
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

  Future<List<MembershipPlan>> _membershipPlans() {
    return PaymentAPI.membershipPlans();
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
