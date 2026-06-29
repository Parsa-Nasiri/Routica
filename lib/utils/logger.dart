import 'package:flutter/foundation.dart';

/// Lightweight logging utility that replaces scattered `debugPrint()` calls.
///
/// In debug mode messages go to the console; in release they are silenced
/// to avoid leaking data and wasting cycles.  Callers use [Log.d] for
/// debug, [Log.w] for warnings, [Log.e] for errors.
class Log {
  Log._();

  static const bool _kReleaseMode = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  static void d(String message) {
    if (_kReleaseMode) return;
    debugPrint('[DEBUG] $message');
  }

  static void w(String message) {
    if (_kReleaseMode) return;
    debugPrint('[WARN] $message');
  }

  static void e(String message, [Object? error, StackTrace? stack]) {
    if (_kReleaseMode) return;
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('  → $error');
    if (stack != null) debugPrint('  → $stack');
  }
}
