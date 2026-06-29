import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_repository.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../theme/routica_theme.dart';
import '../utils/logger.dart';
import '../widgets/routica_animations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _smartRemindersEnabled = false;
  final int _smartReminderHour = 20; // 8 PM default
  bool _isGoogleLoading = false;

  // ── Clear data ───────────────────────────────────────────────

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => _RouticaDialog(
        title: 'Clear All Data?',
        icon: Icons.warning_amber_rounded,
        iconColor: RouticaTheme.danger,
        content: 'This will permanently delete all your habits and history. '
            'This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: RouticaTheme.danger,
        onConfirm: () {
          Navigator.pop(context);
          _showSecondConfirmation();
        },
      ),
    );
  }

  void _showSecondConfirmation() {
    showDialog(
      context: context,
      builder: (context) => _RouticaDialog(
        title: 'Are you absolutely sure?',
        icon: Icons.dangerous_outlined,
        iconColor: RouticaTheme.danger,
        content: 'There is no going back. All data will be lost forever.',
        confirmText: 'Yes, Delete Everything',
        confirmColor: RouticaTheme.danger,
        onConfirm: () {
          ref.read(habitRepositoryProvider.notifier).clearAll();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('All data cleared'),
              backgroundColor: RouticaTheme.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Export ───────────────────────────────────────────────────

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => _RouticaDialog(
        title: 'Export Data',
        icon: Icons.download,
        iconColor: RouticaTheme.success,
        content: 'Export all your habits and history as a JSON backup file. '
            'The file will be saved to your app Documents folder.',
        confirmText: 'Export',
        confirmColor: RouticaTheme.success,
        onConfirm: () async {
          Navigator.pop(context);
          await _exportJsonData();
        },
      ),
    );
  }

  Future<void> _exportJsonData() async {
    try {
      final habits = ref.read(habitRepositoryProvider);
      final jsonString = await BackupService.exportHabitsToJson(habits);
      if (jsonString == null) throw Exception('Failed to create backup');

      final file = await BackupService.saveExportToFile(jsonString);
      if (file == null) throw Exception('Failed to save backup file');

      _showSuccessSnackBar('✓ Backup saved to: ${file.path}');
    } catch (e) {
      Log.e('JSON export failed: $e');
      _showErrorSnackBar('✗ Export failed: $e');
    }
  }

  // ── CSV Export ───────────────────────────────────────────────

  void _showCsvExportDialog() {
    showDialog(
      context: context,
      builder: (context) => _RouticaDialog(
        title: 'Export as CSV',
        icon: Icons.table_chart_outlined,
        iconColor: RouticaTheme.warning,
        content: 'Export a human-readable CSV summary of your habits '
            '(title, category, streaks, completion stats). '
            'Great for spreadsheets or sharing.',
        confirmText: 'Export CSV',
        confirmColor: RouticaTheme.warning,
        onConfirm: () async {
          Navigator.pop(context);
          await _exportCsvData();
        },
      ),
    );
  }

  Future<void> _exportCsvData() async {
    try {
      final habits = ref.read(habitRepositoryProvider);
      final csvString = await BackupService.exportHabitsToCsv(habits);
      if (csvString == null) throw Exception('Failed to create CSV');

      final file = await BackupService.saveCsvToFile(csvString);
      if (file == null) throw Exception('Failed to save CSV file');

      _showSuccessSnackBar('✓ CSV saved to: ${file.path}');
    } catch (e) {
      Log.e('CSV export failed: $e');
      _showErrorSnackBar('✗ CSV export failed: $e');
    }
  }

  // ── Import ───────────────────────────────────────────────────

  void _showImportDialog() {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _RouticaDialog(
        title: 'Import Data',
        icon: Icons.upload,
        iconColor: RouticaTheme.info,
        content: 'Paste your backup JSON below to restore your habits:',
        confirmText: 'Import',
        confirmColor: RouticaTheme.info,
        customContent: TextField(
          controller: jsonController,
          maxLines: 6,
          style: const TextStyle(
            color: RouticaTheme.textPrimary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: '{"version": "2.0", "habits": [...]}',
            hintStyle: const TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            filled: true,
            fillColor: RouticaTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        onConfirm: () async {
          Navigator.pop(context);
          await _importData(jsonController.text);
        },
      ),
    );
  }

  Future<void> _importData(String jsonString) async {
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      _showWarningSnackBar('Please paste your backup JSON first.');
      return;
    }

    try {
      final importedHabits = await BackupService.importHabits(trimmed);
      if (importedHabits == null || importedHabits.isEmpty) {
        throw Exception('No habits found in backup');
      }

      final repo = ref.read(habitRepositoryProvider.notifier);
      for (final habit in importedHabits) {
        await repo.addHabit(habit);
      }

      _showSuccessSnackBar('✓ Imported ${importedHabits.length} habits!');
    } catch (e) {
      Log.e('Import failed: $e');
      _showErrorSnackBar('✗ Import failed: $e');
    }
  }

  // ── Smart reminders ──────────────────────────────────────────

  Future<void> _toggleSmartReminders(bool enabled) async {
    setState(() => _smartRemindersEnabled = enabled);

    if (enabled) {
      final habits = ref.read(habitRepositoryProvider);
      await NotificationService().scheduleAllSmartReminders(
        habits,
        _smartReminderHour,
      );
      _showInfoSnackBar(
        'Smart reminders enabled — you\'ll be reminded '
        'at $_smartReminderHour:00 for incomplete habits.',
      );
    } else {
      await NotificationService().cancelAllNotifications();
      for (final habit in ref.read(habitRepositoryProvider)) {
        if (habit.reminders.isNotEmpty) {
          await NotificationService().scheduleHabitReminders(habit);
        }
      }
    }
  }

  // ── Snackbars ────────────────────────────────────────────────

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(message, RouticaTheme.success),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(message, RouticaTheme.danger),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar('⚠️ $message', RouticaTheme.warning),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar('📌 $message', RouticaTheme.info),
    );
  }

  SnackBar _buildSnackBar(String message, Color color) {
    return SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // App branding card
          StaggerFadeIn(index: 0, child: _buildBrandingCard()),
          const SizedBox(height: 16),

          // Account section (sign-in / sign-out)
          StaggerFadeIn(index: 1, child: _buildAccountSection()),
          const SizedBox(height: 16),

          // Notifications
          StaggerFadeIn(index: 2, child: _buildNotifications()),
          const SizedBox(height: 16),

          // Data & Privacy
          StaggerFadeIn(index: 3, child: _buildDataPrivacy()),
          const SizedBox(height: 16),

          // About
          StaggerFadeIn(index: 4, child: _buildAbout()),
          const SizedBox(height: 16),

          // Info note
          StaggerFadeIn(index: 5, child: _buildInfoNote()),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: RouticaTheme.textPrimary),
            onPressed: widget.onBack,
          ),
        const SizedBox(width: 4),
        const Text(
          'Settings',
          style: TextStyle(
            color: RouticaTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Branding card ────────────────────────────────────────────

  Widget _buildBrandingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RouticaTheme.brandGradient,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Routica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Build better habits, one day at a time',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
            ),
            child: const Text(
              'v4.1.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Account section ──────────────────────────────────────────

  Widget _buildAccountSection() {
    final user = AuthService.instance.currentUser;
    final isGuest = ref.read(guestModeProvider);
    final isLoggedIn = user != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            border: Border.all(color: RouticaTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isLoggedIn) ...[
                  // Logged in — show user info + sign out
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: RouticaTheme.iconBg(RouticaTheme.accent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: RouticaTheme.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email ?? 'Signed in',
                              style: const TextStyle(
                                color: RouticaTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (user.appMetadata['provider'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'via ${user.appMetadata['provider']}',
                                  style: const TextStyle(
                                    color: RouticaTheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        await AuthService.instance.signOut();
                        if (context.mounted) {
                          ref.read(guestModeProvider.notifier).disable();
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: TextButton.styleFrom(
                        foregroundColor: RouticaTheme.danger,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else if (isGuest) ...[
                  // Guest mode — offer sign-in
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: RouticaTheme.iconBg(RouticaTheme.warning),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_off_outlined,
                          color: RouticaTheme.warning,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest Mode',
                              style: TextStyle(
                                color: RouticaTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your data is local-only. Sign in to sync.',
                              style: TextStyle(
                                color: RouticaTheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Google Sign-In button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
                      child: InkWell(
                        onTap: _isGoogleLoading
                            ? null
                            : () async {
                                setState(() => _isGoogleLoading = true);
                                final error = await AuthService.instance.signInWithGoogle();
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: RouticaTheme.danger,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    // Disable guest mode on successful sign-in
                                    ref.read(guestModeProvider.notifier).disable();
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
                        child: Center(
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF4285F4),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFF4285F4),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Not logged in, not guest — show both options
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: RouticaTheme.iconBg(RouticaTheme.accent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: RouticaTheme.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sign in to sync your habits across devices',
                          style: TextStyle(
                            color: RouticaTheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
                      child: InkWell(
                        onTap: _isGoogleLoading
                            ? null
                            : () async {
                                setState(() => _isGoogleLoading = true);
                                final error = await AuthService.instance.signInWithGoogle();
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: RouticaTheme.danger,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
                        child: Center(
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF4285F4),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFF4285F4),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Section title ────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: RouticaTheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Notifications ────────────────────────────────────────────

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notifications'),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            border: Border.all(color: RouticaTheme.border),
          ),
          child: Column(
            children: [
              // Habit Reminders
              _buildToggleRow(
                title: 'Habit Reminders',
                subtitle: 'Get notified about your habits',
                icon: Icons.notifications,
                accent: RouticaTheme.info,
                value: _notificationsEnabled,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _notificationsEnabled = val);
                },
              ),
              const Divider(height: 1, color: RouticaTheme.border),
              // Smart Reminders
              _buildToggleRow(
                title: 'Smart Reminders',
                subtitle: 'Context-aware nudges for incomplete habits',
                icon: Icons.lightbulb_outline,
                accent: RouticaTheme.success,
                value: _smartRemindersEnabled,
                enabled: _notificationsEnabled,
                onChanged: _notificationsEnabled
                    ? (val) => _toggleSmartReminders(val)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onChanged?.call(!value);
            }
          : null,
      borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIconContainer(icon, accent),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: enabled ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: RouticaTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: RouticaTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSwitch(value, accent, enabled: enabled),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: RouticaTheme.iconBg(accent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }

  Widget _buildSwitch(bool value, Color activeColor, {bool enabled = true}) {
    return AnimatedContainer(
      duration: RouticaTheme.animFast,
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: !enabled
            ? RouticaTheme.borderStrong
            : value
                ? activeColor
                : RouticaTheme.borderStrong,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedAlign(
        duration: RouticaTheme.animFast,
        curve: Curves.easeInOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Data & Privacy ──────────────────────────────────────────

  Widget _buildDataPrivacy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data & Privacy'),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            border: Border.all(color: RouticaTheme.border),
          ),
          child: Column(
            children: [
              _buildActionRow(
                title: 'Export Data (JSON)',
                subtitle: 'Download full backup with history',
                icon: Icons.download,
                accent: RouticaTheme.success,
                onTap: _showExportDialog,
              ),
              const Divider(height: 1, color: RouticaTheme.border),
              _buildActionRow(
                title: 'Export as CSV',
                subtitle: 'Human-readable summary for spreadsheets',
                icon: Icons.table_chart_outlined,
                accent: RouticaTheme.warning,
                onTap: _showCsvExportDialog,
              ),
              const Divider(height: 1, color: RouticaTheme.border),
              _buildActionRow(
                title: 'Import Data',
                subtitle: 'Restore from a JSON backup',
                icon: Icons.upload,
                accent: RouticaTheme.info,
                onTap: _showImportDialog,
              ),
              const Divider(height: 1, color: RouticaTheme.border),
              _buildActionRow(
                title: 'Clear All Data',
                subtitle: 'Permanently delete all habits',
                icon: Icons.delete_outline,
                accent: RouticaTheme.danger,
                isDestructive: true,
                onTap: _showClearDataConfirmation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIconContainer(icon, accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? RouticaTheme.dangerLight
                          : RouticaTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: RouticaTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: RouticaTheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── About ────────────────────────────────────────────────────

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About'),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
            border: Border.all(color: RouticaTheme.border),
          ),
          child: Column(
            children: [
              _buildActionRow(
                title: 'Version',
                subtitle: '4.1.0',
                icon: Icons.info_outline,
                accent: RouticaTheme.secondary,
                onTap: () {},
              ),
              const Divider(height: 1, color: RouticaTheme.border),
              _buildActionRow(
                title: 'Rate Routica',
                subtitle: 'Enjoying the app? Let us know!',
                icon: Icons.star_outline,
                accent: RouticaTheme.warning,
                onTap: () {},
              ),
              const Divider(height: 1, color: RouticaTheme.border),
              _buildActionRow(
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                icon: Icons.privacy_tip_outlined,
                accent: RouticaTheme.accent,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Info note ────────────────────────────────────────────────

  Widget _buildInfoNote() {
    return Container(
      decoration: BoxDecoration(
        color: RouticaTheme.iconBg(RouticaTheme.info),
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.info.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            color: RouticaTheme.info,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your habit data is stored locally on your device. '
              'Nothing is sent to any server.',
              style: TextStyle(
                color: RouticaTheme.infoLight,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom dialog ───────────────────────────────────────────────

class _RouticaDialog extends StatelessWidget {
  const _RouticaDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    required this.confirmText,
    required this.confirmColor,
    required this.onConfirm,
    this.customContent,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String content;
  final String confirmText;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final Widget? customContent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: RouticaTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RouticaTheme.radiusDialog),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RouticaTheme.iconBg(iconColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: RouticaTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customContent == null)
            Text(
              content,
              style: const TextStyle(
                color: RouticaTheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            )
          else ...[
            Text(
              content,
              style: const TextStyle(
                color: RouticaTheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            customContent!,
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: RouticaTheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RouticaTheme.radiusButton),
            ),
          ),
          onPressed: onConfirm,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
