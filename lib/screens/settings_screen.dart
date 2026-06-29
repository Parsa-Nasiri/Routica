import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_repository.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../theme/routica_theme.dart';
import '../utils/logger.dart';

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

  // Bug 5 fix: removed the dead `_highContrast` variable that was declared
  // but never used, never wired to any UI, and never persisted.

  // F9: Smart reminders setting
  bool _smartRemindersEnabled = false;
  int _smartReminderHour = 20; // 8 PM default

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your habits and history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondConfirmation();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSecondConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'There is no going back. All data will be lost forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(habitRepositoryProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Yes, Delete Everything',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── JSON Export ──────────────────────────────────────────────

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Export all your habits and history as a JSON backup file. '
          'The file will be saved to your app Documents folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RouticaTheme.success,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _exportJsonData();
            },
            child: const Text('Export', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJsonData() async {
    try {
      final habits = ref.read(habitRepositoryProvider);
      final jsonString = await BackupService.exportHabitsToJson(habits);
      if (jsonString == null) {
        throw Exception('Failed to create backup');
      }

      final file = await BackupService.saveExportToFile(jsonString);
      if (file == null) {
        throw Exception('Failed to save backup file');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Backup saved to: ${file.path}'),
          backgroundColor: RouticaTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Log.e('JSON export failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Export failed: $e'),
          backgroundColor: RouticaTheme.danger,
        ),
      );
    }
  }

  // ── F16: CSV Export ──────────────────────────────────────────

  void _showCsvExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export as CSV'),
        content: const Text(
          'Export a human-readable CSV summary of your habits '
          '(title, category, streaks, completion stats). '
          'Great for spreadsheets or sharing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RouticaTheme.success,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _exportCsvData();
            },
            child: const Text('Export CSV', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsvData() async {
    try {
      final habits = ref.read(habitRepositoryProvider);
      final csvString = await BackupService.exportHabitsToCsv(habits);
      if (csvString == null) {
        throw Exception('Failed to create CSV');
      }

      final file = await BackupService.saveCsvToFile(csvString);
      if (file == null) {
        throw Exception('Failed to save CSV file');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ CSV saved to: ${file.path}'),
          backgroundColor: RouticaTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Log.e('CSV export failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ CSV export failed: $e'),
          backgroundColor: RouticaTheme.danger,
        ),
      );
    }
  }

  // ── Import (Bug fix: was a no-op snackbar) ───────────────────

  void _showImportDialog() {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your backup JSON below to restore your habits:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonController,
                maxLines: 8,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '{"version": "2.0", "habits": [...]}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RouticaTheme.info,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _importData(jsonController.text);
            },
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(String jsonString) async {
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please paste your backup JSON first.'),
          backgroundColor: RouticaTheme.warning,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Imported ${importedHabits.length} habits!'),
          backgroundColor: RouticaTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Log.e('Import failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Import failed: $e'),
          backgroundColor: RouticaTheme.danger,
        ),
      );
    }
  }

  // ── F9: Smart reminders toggle ───────────────────────────────

  Future<void> _toggleSmartReminders(bool enabled) async {
    setState(() => _smartRemindersEnabled = enabled);

    if (enabled) {
      final habits = ref.read(habitRepositoryProvider);
      await NotificationService().scheduleAllSmartReminders(
        habits,
        _smartReminderHour,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📌 Smart reminders enabled — you\'ll be reminded '
            'at ${_smartReminderHour}:00 for incomplete habits.',
          ),
          backgroundColor: RouticaTheme.info,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      await NotificationService().cancelAllNotifications();
      // Re-schedule normal reminders
      for (final habit in ref.read(habitRepositoryProvider)) {
        if (habit.reminders.isNotEmpty) {
          await NotificationService().scheduleHabitReminders(habit);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: RouticaTheme.textPrimary),
                        onPressed: widget.onBack,
                      ),
                    const SizedBox(width: 4),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: RouticaTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAppearance(),
                const SizedBox(height: 16),
                _buildOnlineAccount(),
                const SizedBox(height: 16),
                _buildNotifications(),
                const SizedBox(height: 16),
                _buildDataPrivacy(),
                const SizedBox(height: 16),
                _buildAbout(),
                const SizedBox(height: 16),
                _buildInfoNote(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 12),
      ),
    );
  }

  Widget _buildAppearance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Appearance'),
        Opacity(
          opacity: 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: RouticaTheme.surface,
              borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
              border: Border.all(color: RouticaTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x33A855F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette,
                        size: 20, color: Color(0xFFC084FC)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme',
                            style: TextStyle(color: RouticaTheme.textPrimary)),
                        SizedBox(height: 2),
                        Text('See The App In Different Styles!',
                            style: TextStyle(
                                color: RouticaTheme.onSurfaceVariant,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x332B2EEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: RouticaTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        Opacity(
          opacity: 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: RouticaTheme.surface,
              borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
              border: Border.all(color: RouticaTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x333B82F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud,
                        size: 20, color: Color(0xFF60A5FA)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Online Account',
                            style:
                                TextStyle(color: RouticaTheme.textPrimary)),
                        SizedBox(height: 2),
                        Text('Sync across devices',
                            style: TextStyle(
                                color: RouticaTheme.onSurfaceVariant,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x332B2EEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: RouticaTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSwitch(bool value, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: value ? activeColor : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(4),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

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
              // Habit Reminders toggle
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _notificationsEnabled = !_notificationsEnabled;
                  });
                },
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x333B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications,
                            size: 20, color: Color(0xFF60A5FA)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Habit Reminders',
                                style: TextStyle(
                                    color: RouticaTheme.textPrimary)),
                            SizedBox(height: 2),
                            Text('Get notified about your habits',
                                style: TextStyle(
                                    color: RouticaTheme.onSurfaceVariant,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      _buildCustomSwitch(
                          _notificationsEnabled, RouticaTheme.info),
                    ],
                  ),
                ),
              ),

              // F9: Smart Reminders toggle
              const Divider(height: 1, color: RouticaTheme.border),
              InkWell(
                onTap: _notificationsEnabled
                    ? () => _toggleSmartReminders(!_smartRemindersEnabled)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x3310B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lightbulb_outline,
                            size: 20, color: RouticaTheme.successLight),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart Reminders',
                                style: TextStyle(
                                    color: RouticaTheme.textPrimary)),
                            SizedBox(height: 2),
                            Text('Context-aware nudges for incomplete habits',
                                style: TextStyle(
                                    color: RouticaTheme.onSurfaceVariant,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      _buildCustomSwitch(
                          _smartRemindersEnabled, RouticaTheme.success),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              // JSON Export
              _buildSettingsRowWithIcon(
                title: 'Export Data (JSON)',
                subtitle: 'Download full backup with history',
                icon: Icons.download,
                iconBgColor: const Color(0x3310B981),
                iconColor: const Color(0xFF4ADE80),
                onTap: _showExportDialog,
              ),
              const Divider(height: 1, color: RouticaTheme.border),

              // F16: CSV Export
              _buildSettingsRowWithIcon(
                title: 'Export as CSV',
                subtitle: 'Human-readable summary for spreadsheets',
                icon: Icons.table_chart_outlined,
                iconBgColor: const Color(0x33F59E0B),
                iconColor: const Color(0xFFFBBF24),
                onTap: _showCsvExportDialog,
              ),
              const Divider(height: 1, color: RouticaTheme.border),

              // Import (now functional!)
              _buildSettingsRowWithIcon(
                title: 'Import Data',
                subtitle: 'Restore from a JSON backup',
                icon: Icons.upload,
                iconBgColor: const Color(0x333B82F6),
                iconColor: const Color(0xFF60A5FA),
                onTap: _showImportDialog,
              ),
              const Divider(height: 1, color: RouticaTheme.border),

              // Clear data
              _buildSettingsRowWithIcon(
                title: 'Clear All Data',
                subtitle: 'Permanently delete all habits',
                icon: Icons.delete,
                iconBgColor: const Color(0x33EF4444),
                iconColor: const Color(0xFFF87171),
                isDestructive: true,
                onTap: _showClearDataConfirmation,
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          child: _buildSettingsRowWithIcon(
            title: 'Version',
            subtitle: '4.1.0',
            icon: Icons.info_outline,
            iconBgColor: const Color(0x336366F1),
            iconColor: const Color(0xFF818CF8),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRowWithIcon({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1A3B82F6),
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: const Color(0x333B82F6)),
      ),
      padding: const EdgeInsets.all(20),
      child: const Text(
        'ℹ️  Your habit data is stored locally on your device.',
        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 14),
      ),
    );
  }
}
