part of 'index.dart';

final class MockService {
  bool enabled = true;
  Duration defaultDelay = const Duration(milliseconds: 250);
  bool shouldReturnEmpty = false;
  bool shouldFail = false;
  final Set<String> emptyKeys = <String>{};
  final Map<String, String> failureMessages = <String, String>{};

  void configure({
    bool? enabled,
    bool? shouldReturnEmpty,
    bool? shouldFail,
    Duration? defaultDelay,
    Iterable<String>? emptyKeys,
    Map<String, String>? failureMessages,
  }) {
    if (enabled != null) {
      this.enabled = enabled;
    }
    if (shouldReturnEmpty != null) {
      this.shouldReturnEmpty = shouldReturnEmpty;
    }
    if (shouldFail != null) {
      this.shouldFail = shouldFail;
    }
    if (defaultDelay != null) {
      this.defaultDelay = defaultDelay;
    }
    if (emptyKeys != null) {
      this.emptyKeys
        ..clear()
        ..addAll(emptyKeys);
    }
    if (failureMessages != null) {
      this.failureMessages
        ..clear()
        ..addAll(failureMessages);
    }
  }

  void reset() {
    enabled = true;
    shouldReturnEmpty = false;
    shouldFail = false;
    defaultDelay = const Duration(milliseconds: 250);
    emptyKeys.clear();
    failureMessages.clear();
  }

  void setEmptyFor(String key, {bool enabled = true}) {
    if (enabled) {
      emptyKeys.add(key);
      return;
    }
    emptyKeys.remove(key);
  }

  void setFailureFor(
    String key, {
    bool enabled = true,
    String message = 'Mock request failed',
  }) {
    if (enabled) {
      failureMessages[key] = message;
      return;
    }
    failureMessages.remove(key);
  }

  Future<T> resolve<T>(T data, {Duration? delay, String? mockKey}) async {
    await Future<void>.delayed(delay ?? defaultDelay);
    _throwIfFailed(mockKey);
    return data;
  }

  Future<List<T>> resolveList<T>(
    List<T> data, {
    List<T>? empty,
    Duration? delay,
    String? mockKey,
  }) async {
    await Future<void>.delayed(delay ?? defaultDelay);
    _throwIfFailed(mockKey);
    if (shouldReturnEmpty || (mockKey != null && emptyKeys.contains(mockKey))) {
      return empty ?? <T>[];
    }
    return data;
  }

  Future<T> reject<T>(String message, {Duration? delay}) async {
    await Future<void>.delayed(delay ?? defaultDelay);
    throw StateError(message);
  }

  void _throwIfFailed(String? mockKey) {
    if (mockKey != null && failureMessages.containsKey(mockKey)) {
      throw ApiException(
        type: ApiErrorType.serviceBusy,
        message: failureMessages[mockKey],
      );
    }
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serviceBusy,
        message: 'Mock request failed',
      );
    }
  }
}
