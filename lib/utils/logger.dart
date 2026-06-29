/// Lightweight logging utility that replaces scattered `print()` calls.
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
    // ignore: avoid_print
    print('[DEBUG] $message');
  }

  static void w(String message) {
    if (_kReleaseMode) return;
    // ignore: avoid_print
    print('[WARN] $message');
  }

  static void e(String message, [Object? error, StackTrace? stack]) {
    if (_kReleaseMode) return;
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) print('  → $error');
    if (stack != null) print('  → $stack');
  }
}
