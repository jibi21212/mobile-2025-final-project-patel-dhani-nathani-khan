import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Keep timers for scheduled stuff (keyed by task id)
  final Map<int, Timer> _taskTimers = {};
  Timer? _testTimer;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        'task_reminders',
        'Task Reminders',
        description: 'Reminders for upcoming tasks',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    _initialized = true;
    print('NotificationService initialized (using Timer and show)');
  }

  NotificationDetails _details() {
    return const NotificationDetails(
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Instant test notification
  Future<void> testNotification() async {
    await initialize();

    await _notifications.show(
      999,
      'Test Notification',
      'This is a test notification from Task Manager',
      _details(),
    );
    print('Immediate test notification shown');
  }

  /// "Scheduled" test notification using a Dart Timer (10 seconds from now)
  Future<void> testScheduledNotification() async {
    await initialize();

    _testTimer?.cancel(); // cancel previous if any

    print('Scheduling TEST notification for 10 seconds from now');
    _testTimer = Timer(const Duration(seconds: 10), () async {
      print('Firing TEST scheduled notification now');
      await _notifications.show(
        998,
        'Test Scheduled Notification',
        'This notification was scheduled 10 seconds ago',
        _details(),
      );
    });
  }

  /// Schedule reminder for a task:
  /// - 1 hour before due if possible
  /// - If that time is in the past, fire in 10 seconds (for testing)
  Future<void> scheduleTaskReminder(Task task) async {
    await initialize();

    if (task.due == null || task.id == null) {
      print(
        'Not scheduling: missing due or id (due=${task.due}, id=${task.id})',
      );
      return;
    }

    if (task.status == TaskStatus.done) {
      print('Not scheduling: task ${task.id} is done');
      return;
    }

    // Cancel any old timer for this task
    _taskTimers[task.id!]?.cancel();

    final now = DateTime.now();
    DateTime reminderTime = task.due!.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(now)) {
      // For testing or close deadlines, just fire in 10 seconds
      reminderTime = now.add(const Duration(seconds: 10));
      print(
        'Reminder time was in the past, using ${reminderTime.toLocal()} '
        '(10 seconds from now for testing)',
      );
    } else {
      print(
        'Scheduling reminder for task ${task.id} at ${reminderTime.toLocal()} '
        '(1 hour before ${task.due})',
      );
    }

    final delay = reminderTime.difference(now);
    final id = task.id!;

    _taskTimers[id] = Timer(delay, () async {
      print('Firing reminder for task $id at ${DateTime.now().toLocal()}');
      await _notifications.show(
        id,
        'Task Reminder: ${task.title}',
        task.description ?? 'Task is coming up',
        _details(),
      );
    });
  }

  Future<void> cancelTaskReminder(int id) async {
    await initialize();
    _taskTimers[id]?.cancel();
    _taskTimers.remove(id);
    await _notifications.cancel(id);
    print('Cancelled reminder and timer for task $id');
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    for (final timer in _taskTimers.values) {
      timer.cancel();
    }
    _taskTimers.clear();
    _testTimer?.cancel();
    _testTimer = null;
    await _notifications.cancelAll();
    print('Cancelled all notifications and timers');
  }
}
