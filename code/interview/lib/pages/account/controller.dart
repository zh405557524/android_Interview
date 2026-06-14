part of 'index.dart';

final class AccountController extends GetxController {
  final UserStore userStore = Get.find<UserStore>();
  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  ViewState get pageState {
    if (loading.value && userStore.isLoggedIn) {
      return ViewState.loading;
    }
    return ViewState.success;
  }

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (!userStore.isLoggedIn) {
      loading.value = false;
      errorMessage.value = null;
      return;
    }

    loading.value = true;
    errorMessage.value = null;
    try {
      final profile = _useMock ? await _mockProfile() : await UserAPI.profile();
      if (userStore.isLoggedIn) {
        userStore.setProfile(profile);
      }
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  Future<void> copyInviteCode() async {
    try {
      await Clipboard.setData(ClipboardData(text: userStore.inviteCode.value));
      CustomToast.text('邀请码已复制');
    } catch (_) {
      CustomToast.text('复制失败，请稍后重试');
    }
  }

  Future<void> logout() async {
    try {
      if (_useMock) {
        await _mock.resolve<bool>(true, mockKey: 'user.logout');
      } else {
        await UserAPI.logout();
      }
    } on ApiException catch (error) {
      CustomToast.text(error.userMessage);
      return;
    }
    await userStore.clearSession();
    Get.find<HttpService>().setToken(null);
  }

  Future<UserProfile> _mockProfile() {
    return _mock.resolve<UserProfile>(
      const UserProfile(
        id: 'user_mock_001',
        maskedPhone: '138****2026',
        inviteCode: 'JS2026',
        pointsBalance: 120,
        isVip: false,
        nickname: '漫剧工坊用户',
      ),
      mockKey: 'user.profile',
    );
  }
}
