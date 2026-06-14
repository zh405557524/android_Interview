/// 当前用户资料。
///
/// 用于我的页、全局登录态和权益入口展示。
final class UserProfile {
  const UserProfile({
    required this.id,
    required this.maskedPhone,
    required this.inviteCode,
    required this.pointsBalance,
    required this.isVip,
    this.nickname,
    this.avatarUrl,
  });

  /// 用户 id。
  final String id;

  /// 脱敏手机号展示文案。
  final String maskedPhone;

  /// 当前用户邀请码。
  final String inviteCode;

  /// 当前积分余额。
  final int pointsBalance;

  /// 是否已开通会员。
  final bool isVip;

  /// 可选昵称。
  final String? nickname;

  /// 可选头像地址。
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: '${json['id'] ?? ''}',
      maskedPhone: '${json['maskedPhone'] ?? json['phoneMasked'] ?? '未登录'}',
      inviteCode: '${json['inviteCode'] ?? ''}',
      pointsBalance: (json['pointsBalance'] as num?)?.toInt() ?? 0,
      isVip: _isVip(json),
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'maskedPhone': maskedPhone,
      'inviteCode': inviteCode,
      'pointsBalance': pointsBalance,
      'isVip': isVip,
      if (nickname != null) 'nickname': nickname,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

bool _isVip(Map<String, dynamic> json) {
  if (_truthy(json['isVip'])) {
    return true;
  }

  final status = _firstText(json, const <String>[
    'vipStatus',
    'memberStatus',
    'membershipStatus',
  ]);
  if (status != null) {
    return switch (status.trim().toUpperCase()) {
      'ACTIVE' || 'VIP' || 'MEMBER' || 'MEMBERSHIP' || 'VALID' => true,
      _ => false,
    };
  }

  return _truthy(json['userMember'] ?? json['user_member'] ?? json['member']);
}

String? _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && '$value'.trim().isNotEmpty) {
      return '$value';
    }
  }
  return null;
}

bool _truthy(Object? value) {
  if (value == true) {
    return true;
  }
  if (value is num) {
    return value == 1;
  }
  final text = '${value ?? ''}'.trim().toUpperCase();
  return text == '1' || text == 'TRUE' || text == 'YES' || text == 'Y';
}
