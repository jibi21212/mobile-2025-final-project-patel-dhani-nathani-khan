import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(initSettings);
    print('Notifications initialized: $initialized');
    
    // Create notification channels for Android
    await _createNotificationChannels();
    
    _initialized = true;

    // Request permissions for Android 13+
    await _requestPermissions();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Channel for task reminders
      const reminderChannel = AndroidNotificationChannel(
        'task_reminders',
        'Task Reminders',
        description: 'Reminders for upcoming tasks',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      // Channel for task updates
      const updateChannel = AndroidNotificationChannel(
        'task_updates',
        'Task Updates',
        description: 'Notifications for task updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      await androidPlugin.createNotificationChannel(reminderChannel);
      await androidPlugin.createNotificationChannel(updateChannel);
      print('Notification channels created');
    }
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('Android notification permission granted: $granted');
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('iOS notification permission granted: $granted');
    }
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (task.due == null || task.id == null) {
      print('Cannot schedule notification: task.due=${task.due}, task.id=${task.id}');
      return;
    }

    final now = DateTime.now();
    if (task.due!.isBefore(now)) {
      print('Cannot schedule notification: task due date is in the past (${task.due})');
      return;
    }

    // Schedule notification 1 hour before due time
    final reminderTime = task.due!.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(now)) {
      print('Cannot schedule notification: reminder time is in the past (${reminderTime})');
      return;
    }

    print('Scheduling notification for task ${task.id} (${task.title}) at $reminderTime');
    
    try {
      await _notifications.zonedSchedule(
        task.id!,
        'Task Reminder: ${task.title}',
        task.description ?? 'Task is due in 1 hour',
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Reminders for upcoming tasks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('✓ Notification scheduled successfully for task ${task.id} at $reminderTime');
    } catch (e) {
      print('✗ Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _notifications.cancel(taskId);
  }

  Future<void> showImmediateNotification(String title, String body) async {
    print('Showing immediate notification: $title - $body');
    
    const androidDetails = AndroidNotificationDetails(
      'task_updates',
      'Task Updates',
      channelDescription: 'Notifications for task updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );
      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Test method to schedule a notification 10 seconds from now
  Future<void> testScheduledNotification() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 10));
    
    print('Scheduling test notification for $testTime (10 seconds from now)');
    
    try {
      await _notifications.zonedSchedule(
        999999, // Use a unique ID for test
        'Test Scheduled Notification',
        'This notification was scheduled 10 seconds ago',
        tz.TZDateTime.from(testTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Reminders for upcoming tasks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('✓ Test notification scheduled successfully for $testTime');
    } catch (e) {
      print('✗ Error scheduling test notification: $e');
    }
  }
}
