// lib/services/app_logger.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger(
    filter: ProductionFilter(), // Only log warnings and above in production
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    output: ConsoleOutput(), // You can add file output for production later
  );

  // Verbose logging for development only
  static void verbose(String message, [String? tag]) {
    if (kDebugMode) {
      _logger.v(_formatMessage(message, tag));
    }
  }

  // Debug information
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      _logger.d(_formatMessage(message, tag));
    }
  }

  // Important information (always logged)
  static void info(String message, [String? tag]) {
    _logger.i(_formatMessage(message, tag));
  }

  // Warnings
  static void warning(String message, [String? tag]) {
    _logger.w(_formatMessage(message, tag));
  }

  // Errors with stack traces
  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    final formattedMessage = _formatMessage(message, tag);
    if (error != null) {
      _logger.e('$formattedMessage\nError Details: $error', 
        error: error, 
        stackTrace: stackTrace ?? StackTrace.current
      );
    } else {
      _logger.e(formattedMessage, stackTrace: stackTrace);
    }
  }

  // What a Terrible Failure (critical errors)
  static void wtf(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    final formattedMessage = _formatMessage(message, tag);
    _logger.wtf(formattedMessage, error: error, stackTrace: stackTrace);
  }

  // Authentication specific logs
  static void auth(String message, [dynamic error]) {
    if (error != null) {
      warning('AUTH: $message - Error: $error', 'AUTH');
    } else {
      info('AUTH: $message', 'AUTH');
    }
  }

  // Firestore specific logs
  static void firestore(String message, [dynamic error]) {
    if (error != null) {
      error('FIRESTORE: $message', error, StackTrace.current, 'FIRESTORE');
    } else {
      debug('FIRESTORE: $message', 'FIRESTORE');
    }
  }

  // Image processing logs
  static void imageProcessing(String message, [dynamic error]) {
    if (error != null) {
      error('IMAGE: $message', error, StackTrace.current, 'IMAGE');
    } else {
      debug('IMAGE: $message', 'IMAGE');
    }
  }

  // Reservation specific logs
  static void reservation(String message, [dynamic error]) {
    if (error != null) {
      error('RESERVATION: $message', error, StackTrace.current, 'RESERVATION');
    } else {
      info('RESERVATION: $message', 'RESERVATION');
    }
  }

  // UI interaction logs
  static void ui(String message) {
    debug('UI: $message', 'UI');
  }

  // Format message with optional tag
  static String _formatMessage(String message, String? tag) {
    return tag != null ? '[$tag] $message' : message;
  }
}