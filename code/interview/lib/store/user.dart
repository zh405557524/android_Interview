part of 'index.dart';

final class UserStore extends GetxController {
  static const String _sessionKey = 'auth.session';

  final RxnString token = RxnString();
  final RxnString refreshToken = RxnString();
  final RxString maskedPhone = '未登录'.obs;
  final RxString inviteCode = 'JS2026'.obs;
  final RxInt points = 0.obs;
  final RxBool isVip = false.obs;

  UserProfile? _profile;

  bool get isLoggedIn => token.value?.isNotEmpty ?? false;

  void setSession({
    required String accessToken,
    required String phone,
    String? inviteCode,
    int initialPoints = 0,
    bool vip = false,
  }) {
    token.value = accessToken;
    refreshToken.value = null;
    setProfile(
      UserProfile(
        id: '',
        maskedPhone: phone,
        inviteCode: inviteCode ?? this.inviteCode.value,
        pointsBalance: initialPoints,
        isVip: vip,
      ),
    );
  }

  void setProfile(UserProfile profile) {
    _profile = profile;
    maskedPhone.value = profile.maskedPhone;
    inviteCode.value = profile.inviteCode;
    points.value = profile.pointsBalance;
    isVip.value = profile.isVip;
    unawaited(_persistSession());
  }

  void setSessionFromAuth(AuthSession session) {
    _applySession(session);
    unawaited(_persistSession());
  }

  Future<void> saveSessionFromAuth(AuthSession session) async {
    _applySession(session);
    await _persistSession();
  }

  bool restoreSession() {
    final data = _read(_sessionKey);
    if (data is! Map) {
      return false;
    }

    final session = AuthSession.fromJson(Map<String, dynamic>.from(data));
    if (session.accessToken.trim().isEmpty) {
      unawaited(clearSession());
      return false;
    }

    _applySession(session);
    return true;
  }

  void addPoints(int amount) {
    points.value += amount;
    unawaited(_persistSession());
  }

  void markVipActive() {
    isVip.value = true;
    unawaited(_persistSession());
  }

  Future<void> clearSession() async {
    _clearMemory();
    await _remove(_sessionKey);
  }

  void _applySession(AuthSession session) {
    token.value = session.accessToken;
    refreshToken.value = session.refreshToken;
    setProfile(session.profile);
  }

  void _clearMemory() {
    token.value = null;
    refreshToken.value = null;
    _profile = null;
    maskedPhone.value = '未登录';
    inviteCode.value = 'JS2026';
    points.value = 0;
    isVip.value = false;
  }

  Future<void> _persistSession() async {
    final accessToken = token.value;
    final profile = _profile;
    if (accessToken == null || accessToken.isEmpty || profile == null) {
      return;
    }
    await _write(
      _sessionKey,
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken.value ?? '',
        profile: profile,
      ).toJson(),
    );
  }

  Object? _read(String key) {
    try {
      return GetStorage().read<Object?>(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Object? value) async {
    try {
      await GetStorage().write(key, value);
    } catch (_) {
      // Storage may be unavailable in narrow unit tests; keep in-memory state.
    }
  }

  Future<void> _remove(String key) async {
    try {
      await GetStorage().remove(key);
    } catch (_) {
      // Storage may be unavailable in narrow unit tests; memory is already reset.
    }
  }
}
