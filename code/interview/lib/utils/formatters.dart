part of 'index.dart';

abstract final class AppFormatters {
  static final NumberFormat _integer = NumberFormat.decimalPattern('zh_CN');

  static String points(int value) => '${_integer.format(value)} 积分';

  static String duration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
