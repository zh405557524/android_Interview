part of 'index.dart';

abstract final class AppLogger {
  static void info(String message) {
    debugPrint('[Narrate] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final errorText = error == null ? '' : ' $error';
    debugPrint('[Narrate][error] $message$errorText');
    if (stackTrace != null) {
      debugPrint('[Narrate][error] $stackTrace');
    }
  }
}
