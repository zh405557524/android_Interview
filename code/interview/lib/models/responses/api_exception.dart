import '../../enums/index.dart';

final class ApiException implements Exception {
  const ApiException({required this.type, String? message, this.statusCode})
    : message = message ?? '';

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  String get userMessage {
    if (message.trim().isNotEmpty) {
      return message;
    }
    return type.fallbackMessage;
  }

  @override
  String toString() => userMessage;
}
