part of 'index.dart';

abstract final class AppConstants {
  static const String appName = 'Offer Hunter';
  static const String appCode = 'android_interview';
  static const String appCodeHeader = 'X-App-Code';
  static const String deviceIdHeader = 'X-Device-Id';
  static const String localServerAddress = 'http://192.168.31.243:8080';
  static const String testServerAddress = 'http://120.25.199.191:8080';
  static const String prodServerAddress = 'https://api.lxwanxiang.com/';
  static const Size designSize = Size(375, 812);
  static const int pointsPerMinute = 20;
}
