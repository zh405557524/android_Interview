final class LoginParams {
  const LoginParams({required this.phone, required this.code, this.inviteCode});

  final String phone;
  final String code;
  final String? inviteCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phone': phone,
      'code': code,
      if (inviteCode?.trim().isNotEmpty == true)
        'inviteCode': inviteCode!.trim(),
    };
  }
}
