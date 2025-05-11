import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiDebugUtils {
  // Enable or disable verbose logging
  static bool verboseLogging = true;

  // Log API request
  static void logRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    dynamic body,
    String tag = 'API_REQUEST',
  }) {
    if (!verboseLogging) return;

    final StringBuffer log = StringBuffer();
    log.writeln('[$tag] =====================================================');
    log.writeln('[$tag] 🚀 REQUEST: $method $url');
    
    if (headers != null) {
      log.writeln('[$tag] 📋 HEADERS:');
      headers.forEach((key, value) {
        // Don't print full authorization token
        if (key.toLowerCase() == 'authorization' && value is String && value.length > 20) {
          log.writeln('[$tag]   $key: ${value.substring(0, 20)}...');
        } else {
          log.writeln('[$tag]   $key: $value');
        }
      });
    }
    
    if (body != null) {
      log.writeln('[$tag] 📦 BODY:');
      if (body is Map || body is List) {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(body);
        final lines = prettyJson.split('\n');
        for (final line in lines) {
          log.writeln('[$tag]   $line');
        }
      } else if (body is String) {
        try {
          // Try to parse as JSON for pretty printing
          final jsonBody = jsonDecode(body);
          final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonBody);
          final lines = prettyJson.split('\n');
          for (final line in lines) {
            log.writeln('[$tag]   $line');
          }
        } catch (_) {
          // If parsing fails, just print the string directly
          log.writeln('[$tag]   $body');
        }
      } else {
        log.writeln('[$tag]   $body');
      }
    }
    
    log.writeln('[$tag] =====================================================');
    debugPrint(log.toString());
  }

  // Log API response
  static void logResponse({
    required String url,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    String tag = 'API_RESPONSE',
    Duration? responseTime,
  }) {
    if (!verboseLogging) return;

    final StringBuffer log = StringBuffer();
    log.writeln('[$tag] =====================================================');
    log.writeln('[$tag] 📥 RESPONSE: $statusCode from $url');
    
    if (responseTime != null) {
      log.writeln('[$tag] ⏱️ TIME: ${responseTime.inMilliseconds}ms');
    }
    
    if (headers != null) {
      log.writeln('[$tag] 📋 HEADERS:');
      headers.forEach((key, value) {
        log.writeln('[$tag]   $key: $value');
      });
    }
    
    if (body != null) {
      log.writeln('[$tag] 📦 BODY:');
      if (body is Map || body is List) {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(body);
        final lines = prettyJson.split('\n');
        for (final line in lines) {
          log.writeln('[$tag]   $line');
        }
      } else if (body is String) {
        try {
          // Try to parse as JSON for pretty printing
          final jsonBody = jsonDecode(body);
          final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonBody);
          final lines = prettyJson.split('\n');
          for (final line in lines) {
            log.writeln('[$tag]   $line');
          }
        } catch (_) {
          // If the body is not valid JSON, just print the first 1000 characters
          if (body.length > 1000) {
            log.writeln('[$tag]   ${body.substring(0, 1000)}...(truncated)');
          } else {
            log.writeln('[$tag]   $body');
          }
        }
      } else {
        log.writeln('[$tag]   $body');
      }
    }
    
    log.writeln('[$tag] =====================================================');
    debugPrint(log.toString());
  }

  // Log error
  static void logError({
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
    String tag = 'API_ERROR',
  }) {
    final StringBuffer log = StringBuffer();
    log.writeln('[$tag] =====================================================');
    log.writeln('[$tag] ❌ ERROR for $url');
    log.writeln('[$tag] 📋 ERROR: $error');
    
    if (stackTrace != null) {
      log.writeln('[$tag] 📋 STACK TRACE:');
      final lines = stackTrace.toString().split('\n');
      for (var i = 0; i < min(10, lines.length); i++) {
        log.writeln('[$tag]   ${lines[i]}');
      }
      if (lines.length > 10) {
        log.writeln('[$tag]   ...(truncated)');
      }
    }
    
    log.writeln('[$tag] =====================================================');
    debugPrint(log.toString());
  }

  static int min(int a, int b) => a < b ? a : b;
}