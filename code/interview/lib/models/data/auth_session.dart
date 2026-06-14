import 'user_profile.dart';

/// 登录成功后的会话信息。
///
/// 包含后续真实请求所需 token，以及初始化用户态所需资料。
final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.profile,
  });

  /// 后端返回的访问 token。
  final String accessToken;

  /// 后端返回的刷新 token；accessToken 过期后用它换取新会话。
  final String refreshToken;

  /// 当前登录用户资料。
  final UserProfile profile;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] ?? json['user'];
    return AuthSession(
      accessToken: '${json['accessToken'] ?? json['token'] ?? ''}',
      refreshToken: '${json['refreshToken'] ?? ''}',
      profile: UserProfile.fromJson(
        profileJson is Map
            ? Map<String, dynamic>.from(profileJson)
            : <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'profile': profile.toJson(),
    };
  }
}
