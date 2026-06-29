import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'models/habit.dart';
import 'screens/auth_wrapper.dart';
import 'services/notification_service.dart';
import 'theme/routica_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitFrequencyPeriodAdapter());
  Hive.registerAdapter(HabitDayStatusAdapter());
  Hive.registerAdapter(HabitHistoryEntryAdapter());
  Hive.registerAdapter(HabitReminderAdapter());

  // Open app settings box (for onboarding/auth state persistence)
  await Hive.openBox('app_settings');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(
    const ProviderScope(
      child: RouticaApp(),
    ),
  );
}

class RouticaApp extends StatelessWidget {
  const RouticaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();

    return MaterialApp(
      title: 'Routica',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: RouticaTheme.scaffoldBackground,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: RouticaTheme.primary,
          secondary: RouticaTheme.secondary,
          surface: RouticaTheme.surface,
          surfaceContainerHighest: RouticaTheme.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: RouticaTheme.appBar,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: RouticaTheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RouticaTheme.radiusDialog),
          ),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: const TextStyle(
            color: RouticaTheme.onSurfaceVariant,
            fontSize: 14,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: RouticaTheme.surface,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: RouticaTheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: RouticaTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: RouticaTheme.onSurface,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: RouticaTheme.surfaceVariant.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            borderSide: const BorderSide(color: RouticaTheme.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            borderSide: const BorderSide(color: RouticaTheme.primary, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: RouticaTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
          ),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: RouticaTheme.surface.withValues(alpha: 0.95),
          elevation: 0,
          height: 64,
          indicatorColor: RouticaTheme.accent.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RouticaTheme.accent,
              );
            }
            return const TextStyle(
              fontSize: 12,
              color: RouticaTheme.onSurfaceVariant,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: RouticaTheme.accent, size: 24);
            }
            return const IconThemeData(
              color: RouticaTheme.onSurfaceVariant,
              size: 24,
            );
          }),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
