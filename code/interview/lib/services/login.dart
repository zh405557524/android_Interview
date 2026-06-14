part of 'index.dart';

final class LoginService extends GetxService {
  Future<AuthSession?>? _refreshingSession;

  HttpService get _http => Get.find<HttpService>();
  UserStore get _userStore => Get.find<UserStore>();

  Future<AuthSession?> refreshSession() {
    final refreshing = _refreshingSession;
    if (refreshing != null) {
      return refreshing;
    }

    final future = _doRefreshSession().whenComplete(() {
      _refreshingSession = null;
    });
    _refreshingSession = future;
    return future;
  }

  Future<AuthSession?> refreshSessionForStartup() async {
    final session = await refreshSession();
    if (session != null && Get.isRegistered<CreationConfigService>()) {
      await Get.find<CreationConfigService>().load();
    }
    return session;
  }

  Future<void> clearSession() async {
    if (!Get.isRegistered<UserStore>()) {
      _http.setToken(null);
      return;
    }
    await _userStore.clearSession();
    _http.setToken(null);
  }

  Future<AuthSession?> _doRefreshSession() async {
    if (!Get.isRegistered<UserStore>()) {
      _http.setToken(null);
      return null;
    }
    if (Get.isRegistered<ConfigStore>() &&
        Get.find<ConfigStore>().mockEnabled.value) {
      return null;
    }

    final refreshToken = _userStore.refreshToken.value?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return null;
    }

    try {
      final response = await _http.post(
        '/api/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
        excludeToken: true,
      );
      final session = AuthSession.fromJson(_dataMap(response));
      if (session.accessToken.trim().isEmpty ||
          session.refreshToken.trim().isEmpty) {
        await clearSession();
        return null;
      }
      await _userStore.saveSessionFromAuth(session);
      _http.setToken(session.accessToken);
      return session;
    } on ApiException catch (error) {
      if (_shouldClearSession(error)) {
        await clearSession();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _shouldClearSession(ApiException error) {
    return switch (error.type) {
      ApiErrorType.unauthenticated ||
      ApiErrorType.forbidden ||
      ApiErrorType.validation ||
      ApiErrorType.notFound => true,
      _ => false,
    };
  }

  Map<String, dynamic> _dataMap(BaseResponse response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }
}
