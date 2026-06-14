part of 'index.dart';

final class RedeemCodeController extends GetxController {
  final TextEditingController codeController = TextEditingController();
  final UserStore userStore = Get.find<UserStore>();

  final RxBool submitting = false.obs;
  final Rxn<RedeemCodeResult> result = Rxn<RedeemCodeResult>();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  Future<void> redeem() async {
    if (submitting.value) {
      return;
    }
    final code = codeController.text.trim();
    if (code.isEmpty) {
      CustomToast.text('请输入兑换码');
      return;
    }
    submitting.value = true;
    try {
      final redeemed = _useMock
          ? await _mockRedeem(code)
          : await RedeemCodeAPI.redeem(code);
      result.value = redeemed;
      _applyLocalReward(redeemed);
      await _refreshProfileSilently();
      codeController.clear();
      CustomToast.success(redeemed.message ?? '兑换成功');
    } on ApiException catch (error, stackTrace) {
      CustomToast.error(
        error.userMessage,
        error: error,
        stackTrace: stackTrace,
        tag: '[RedeemCode]',
      );
    } finally {
      submitting.value = false;
    }
  }

  Future<RedeemCodeResult> _mockRedeem(String code) {
    final upper = code.toUpperCase();
    final result = upper.startsWith('VIP')
        ? RedeemCodeResult(
            code: upper,
            productType: 'MEMBERSHIP',
            membershipDays: 30,
            membershipExpiredAt: DateTime.now().add(const Duration(days: 30)),
            message: '兑换成功，会员权益已生效',
          )
        : RedeemCodeResult(
            code: upper,
            productType: 'POINTS',
            rewardPoints: 100,
            pointsBalance: userStore.points.value + 100,
            message: '兑换成功，积分已到账',
          );
    return _mock.resolve<RedeemCodeResult>(
      result,
      mockKey: 'redeem-code.redeem',
    );
  }

  void _applyLocalReward(RedeemCodeResult redeemed) {
    if (redeemed.isPoints && redeemed.rewardPoints != null) {
      final latestBalance = redeemed.pointsBalance;
      if (latestBalance != null) {
        userStore.points.value = latestBalance;
        return;
      }
      userStore.addPoints(redeemed.rewardPoints!);
    }
    if (redeemed.isMembership) {
      userStore.markVipActive();
    }
  }

  Future<void> _refreshProfileSilently() async {
    if (_useMock || !userStore.isLoggedIn) {
      return;
    }
    try {
      userStore.setProfile(await UserAPI.profile());
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('[RedeemCode] refresh profile failed', error, stackTrace);
    }
  }
}
