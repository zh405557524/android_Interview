part of 'index.dart';

abstract final class AppValidators {
  static const int phoneLength = 11;
  static const int smsCodeMinLength = 4;
  static const int smsCodeMaxLength = 6;

  static final RegExp _digitsRegExp = RegExp(r'^\d+$');
  static final RegExp _phoneRegExp = RegExp(r'^1[3-9]\d{9}$');

  static bool isPhone(String value) {
    return phoneError(value) == null;
  }

  static bool isSmsCode(String value) {
    return smsCodeError(value) == null;
  }

  static String? phoneError(String value) {
    final phone = value.trim();
    if (phone.isEmpty) {
      return '请输入手机号';
    }
    if (!_digitsRegExp.hasMatch(phone)) {
      return '手机号仅支持数字';
    }
    if (phone.length != phoneLength) {
      return '手机号应为$phoneLength位';
    }
    if (!_phoneRegExp.hasMatch(phone)) {
      return '请输入正确的手机号';
    }
    return null;
  }

  static String? smsCodeError(String value) {
    final code = value.trim();
    if (code.isEmpty) {
      return '请输入验证码';
    }
    if (!_digitsRegExp.hasMatch(code)) {
      return '验证码仅支持数字';
    }
    if (code.length < smsCodeMinLength || code.length > smsCodeMaxLength) {
      return '验证码为$smsCodeMinLength-$smsCodeMaxLength位数字';
    }
    return null;
  }

  static String? requiredError(String value, String message) {
    return value.trim().isEmpty ? message : null;
  }

  static String? agreementError(bool accepted, String message) {
    return accepted ? null : message;
  }
}
