import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import '../models/medicine.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._();

  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    final currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // Initialize notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
    // Navigate to medication details or mark as taken
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    // Calculate next notification time
    final nextDoseTime = medicine.getNextDoseTime();

    // Don't schedule if in the past
    if (nextDoseTime.isBefore(DateTime.now())) {
      return;
    }

    // Set up notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD6EFFF), // primaryColor
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      visibility: NotificationVisibility.public,
      actions: [
        AndroidNotificationAction(
          'taken',
          'Mark as Taken',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'medication',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule notification with timezone awareness
    await _notificationsPlugin.zonedSchedule(
      medicine.id.hashCode,
      'Time for ${medicine.name}',
      'Take ${medicine.dosage} ${medicine.dosageUnit} of ${medicine.name}',
      tz.TZDateTime.from(nextDoseTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true, // Deliver notifications when device is in low-power mode
      payload: medicine.id,
    );

    // Schedule a second notification for 30 minutes later if not taken (reminder)
    await _notificationsPlugin.zonedSchedule(
      medicine.id.hashCode + 1,
      'Reminder: ${medicine.name}',
      'You haven\'t marked ${medicine.name} as taken yet',
      tz.TZDateTime.from(nextDoseTime.add(Duration(minutes: 30)), tz.local),
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      payload: medicine.id,
    );
  }

  Future<void> cancelNotification(Medicine medicine) async {
    await _notificationsPlugin.cancel(medicine.id.hashCode);
    await _notificationsPlugin.cancel(medicine.id.hashCode + 1);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> rescheduleNotificationsAfterTimeZoneChange() async {
    // This would be called when the timezone changes
    // Get all active medications and reschedule their notifications
    // This would access the MedicineProvider or repository
    // For each medicine: cancelNotification(medicine) then scheduleNotification(medicine)
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Notifications that show immediately',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
}