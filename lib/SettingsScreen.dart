import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/medicine_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String _selectedReminderTime = '30 minutes';
  String _selectedTheme = 'Light';

  final List<String> _reminderTimes = [
    '15 minutes',
    '30 minutes',
    '1 hour',
    '2 hours',
  ];

  final List<String> _themes = [
    'Light',
    'Dark',
    'System',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedReminderTime = prefs.getString('reminder_time') ?? '30 minutes';
      _selectedTheme = prefs.getString('theme') ?? 'Light';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('reminder_time', _selectedReminderTime);
    await prefs.setString('theme', _selectedTheme);

    // Refresh notifications if needed
    if (_notificationsEnabled) {
      final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
      await medicineProvider.refreshAllNotifications();
    } else {
      // Cancel all notifications if notifications are disabled
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.cancelAllNotifications();
    }
  }

  int _getReminderTimeInMinutes() {
    switch (_selectedReminderTime) {
      case '15 minutes':
        return 15;
      case '1 hour':
        return 60;
      case '2 hours':
        return 120;
      case '30 minutes':
      default:
        return 30;
    }
  }

  void _showRestartAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Theme Changed'),
        content: Text('Please restart the app for the theme changes to take effect.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    // Implementation for exporting medicine data
    // This would be implemented using a file picker and json serialization
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data export feature coming soon')),
    );
  }

  Future<void> _importData() async {
    // Implementation for importing medicine data
    // This would be implemented using a file picker and json deserialization
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data import feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications section
            Text(
              'Notifications',
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 16),

            // Enable notifications switch
            _buildSettingCard(
              child: SwitchListTile(
                title: Text('Enable Notifications'),
                subtitle: Text('Receive reminders for your medications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
              ),
            ),
            SizedBox(height: 12),

            // Reminder time dropdown
            _buildSettingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Text(
                      'Second Reminder Time',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      'When to send a reminder if medication was not marked as taken',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  ListTile(
                    title: DropdownButtonFormField<String>(
                      value: _selectedReminderTime,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _reminderTimes.map((time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedReminderTime = value;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Appearance section
            Text(
              'Appearance',
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 16),

            // Theme selection
            _buildSettingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Text(
                      'Theme',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: DropdownButtonFormField<String>(
                      value: _selectedTheme,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _themes.map((theme) {
                        return DropdownMenuItem<String>(
                          value: theme,
                          child: Text(theme),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTheme = value;
                          });
                          _saveSettings();
                          _showRestartAppDialog();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Data section
            Text(
              'Data Management',
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 16),

            // Export data
            _buildSettingCard(
              child: ListTile(
                leading: Icon(Icons.upload),
                title: Text('Export Data'),
                subtitle: Text('Backup your medicine data'),
                onTap: _exportData,
              ),
            ),
            SizedBox(height: 12),

            // Import data
            _buildSettingCard(
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Import Data'),
                subtitle: Text('Restore from a backup'),
                onTap: _importData,
              ),
            ),
            SizedBox(height: 12),

            // Clear data
            _buildSettingCard(
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Clear All Data', style: TextStyle(color: theme.colorScheme.error)),
                subtitle: Text('Delete all medicines and settings'),
                onTap: () => _showClearDataConfirmation(context),
              ),
            ),
            SizedBox(height: 24),

            // About section
            Text(
              'About',
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 16),

            _buildSettingCard(
              child: ListTile(
                title: Text('MedTracker'),
                subtitle: Text('Version 1.0.0'),
                trailing: Icon(Icons.info_outline),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'MedTracker',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 MedTracker',
                    children: [
                      SizedBox(height: 24),
                      Text('A medication tracking application to help you never miss a dose.'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data?'),
        content: Text(
            'This will permanently delete all your medicines and settings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              // Clear all data
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Clear medicines and cancel notifications
              final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
              final medicines = medicineProvider.medicines;
              for (var medicine in medicines) {
                await medicineProvider.deleteMedicine(medicine.id);
              }

              Navigator.of(context).pop();

              // Notify user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All data cleared')),
              );

              // Reload settings
              _loadSettings();
            },
            child: Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}