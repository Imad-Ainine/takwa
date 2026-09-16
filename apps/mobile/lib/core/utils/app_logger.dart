import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as logging;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Structured logging used in place of scattered `debugPrint`/`print` calls,
/// which are stripped in release builds and give no production visibility.
///
/// [error] and [warning] additionally forward to Sentry (a no-op until a
/// `SENTRY_DSN` is configured — see [AppLogger.init]/main.dart), so a failure
/// caught here is actually visible after release, not just in a local
/// console during development.
class AppLogger {
  AppLogger._();

  static final logging.Logger _root = logging.Logger('takwa');
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    logging.Logger.root.level = kDebugMode
        ? logging.Level.ALL
        : logging.Level.INFO;
    logging.Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName}: ${record.message}',
        );
      }
    });
  }

  static void info(String message) => _root.info(message);

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _root.warning(message, error, stackTrace);
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'message': message}),
      );
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _root.severe(message, error, stackTrace);
    Sentry.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
      hint: Hint.withMap({'message': message}),
    );
  }
}
