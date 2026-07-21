import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static void install() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLogger.debug(
        'Flutter framework error',
        context: {
          'exception_type': details.exception.runtimeType.toString(),
          'message': details.exceptionAsString(),
          'library': details.library,
        },
        error: details.exception,
        stackTrace: details.stack,
      );
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.debug(
        'Uncaught asynchronous error',
        context: {
          'exception_type': error.runtimeType.toString(),
          'message': error.toString(),
        },
        error: error,
        stackTrace: stackTrace,
      );
      return previousPlatformHandler?.call(error, stackTrace) ?? true;
    };
  }
}
