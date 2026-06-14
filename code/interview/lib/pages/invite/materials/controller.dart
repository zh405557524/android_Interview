part of 'index.dart';

/// 推广素材子流程的业务与状态控制类。
///
/// 页面进入时只加载推广素材接口；复制动作继续使用系统剪贴板，分享 SDK 仍保持
/// 当前占位能力。
final class InviteMaterialsController extends GetxController {
  /// 当前用户状态仓库，用于邀请码兜底。
  final UserStore userStore = Get.find<UserStore>();

  /// 推广素材数据，包含邀请链接、海报标题和落地页下载地址。
  final Rxn<InviteMaterial> material = Rxn<InviteMaterial>();

  /// 页面加载状态；驱动推广素材 loading / retry。
  final RxBool loading = false.obs;

  /// 页面加载失败时的用户可见错误文案。
  final RxnString errorMessage = RxnString();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  @override
  void onInit() {
    super.onInit();
    loadMaterials();
  }

  /// 当前页面整体展示状态。
  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    return ViewState.success;
  }

  /// 当前用户邀请码，素材接口为空时使用用户仓库兜底。
  String get inviteCode {
    final code = material.value?.inviteCode.trim();
    return code == null || code.isEmpty ? userStore.inviteCode.value : code;
  }

  /// 当前可复制的推广链接，接口为空时回退为邀请码。
  String get inviteLink {
    final link = material.value?.inviteLink.trim() ?? '';
    return link.isEmpty ? inviteCode : link;
  }

  /// 加载推广素材。
  Future<void> loadMaterials() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      material.value = await _materials();
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 复制当前推广链接。
  Future<void> copyInviteLink() async {
    final text = inviteLink.isEmpty ? inviteCode : inviteLink;
    await _copy(text, inviteLink.isEmpty ? '邀请码已复制' : '邀请链接已复制');
  }

  /// 推广分享占位入口，真实分享 SDK 接入前使用复制链接能力。
  Future<void> shareInvite() async {
    await copyInviteLink();
  }

  /// 获取推广素材，mock 模式下使用素材页私有样例数据。
  Future<InviteMaterial> _materials() {
    if (!_useMock) {
      return InviteAPI.materials();
    }
    return _mock.resolve<InviteMaterial>(
      _mockMaterial,
      mockKey: 'invite.materials',
    );
  }

  Future<void> _copy(String text, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      CustomToast.text(message);
    } catch (_) {
      CustomToast.text('复制失败，请稍后重试');
    }
  }

  static const InviteMaterial _mockMaterial = InviteMaterial(
    inviteCode: 'JS2026',
    inviteLink:
        'https://api.lxwanxiang.com/invite/register.html?inviteCode=JS2026',
    posterTitle: '邀请好友一起用剧说',
    ruleText: '个人代理等级影响直接收益；关系层级只区分直接 1 层和后台开启的一层间接收益。',
    landingDownloadUrl: 'https://api.lxwanxiang.com/invite/download.html',
  );
}
