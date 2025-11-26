import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The logger for this package.
@visibleForTesting
final Logger logger = Logger('App');

/// Whether or not the logging is enabled.
/// 로깅 활성화 여부
bool _enabled = false;

/// Logs the message if logging is enabled.
/// 로깅이 활성화된 경우에만 메시지를 출력
void log(String message, {Level level = Level.INFO}) {
  if (_enabled) {
    logger.log(level, message);
  }
}

StreamSubscription<LogRecord>? _subscription;

/// Forwards diagnostic messages to the dart:developer log() API.
/// 메시지를 dart:developer의 log() API로 전달
void setLogging({bool enabled = false}) {
  _subscription?.cancel();
  _enabled = enabled;
  if (!enabled || hierarchicalLoggingEnabled) {
    return;
  }

  _subscription = logger.onRecord.listen((LogRecord e) {
    // use `dumpErrorToConsole` for severe messages to ensure that severe
    // exceptions are formatted consistently with other Flutter examples and
    // avoids printing duplicate exceptions
    // severe 수준의 메시지에는 `dumpErrorToConsole`을 사용
    // flutter의 다른 예제들과 일관된 형식으로 예외를 출력하고 중복된 예외 출력도 방지
    if (e.level >= Level.SEVERE) {
      final Object? error = e.error;
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(
          exception: error is Exception ? error : Exception(error),
          stack: e.stackTrace,
          library: e.loggerName,
          context: ErrorDescription(e.message),
        ),
      );
    } else {
      _developerLogFunction(e);
    }
  });
}

void _developerLog(LogRecord record) {
  dev.log(
    record.message,
    time: record.time,
    sequenceNumber: record.sequenceNumber,
    level: record.level.value,
    name: record.loggerName,
    zone: record.zone,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}

/// A function that can be set during test to mock the developer log function.
/// test 중에 developer log 함수를 모킹할 수 있도록 설정 가능한 함수
@visibleForTesting
void Function(LogRecord)? testDeveloperLog;

/// The function used to log messages.
/// 실제 메시지 로깅에 사용
void Function(LogRecord) get _developerLogFunction =>
    testDeveloperLog ?? _developerLog;
