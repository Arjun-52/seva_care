import 'dart:developer' as developer;

class AppLogger {
  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'SevaCareApp',
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'SevaCareApp',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void d(String message) {
    developer.log(
      message,
      name: 'SevaCareApp',
      level: 500,
    );
  }
}
