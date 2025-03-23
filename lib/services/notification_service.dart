import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    print('Timezone initialized: ${tz.local.name}');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (response) {
      print('Notification tapped: ${response.payload}');
    });
    print('Notification service initialized successfully');
  }

  Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required DateTime appointmentTime,
    required String dietitianName,
  }) async {
    print('=== Notification Scheduling Debug Info ===');
    print('Appointment ID: $appointmentId');
    print('Current Timezone: ${tz.local.name}');
    print('Appointment Time: $appointmentTime');

    // Hemen bir bildirim gönder
    await _notifications.show(
      appointmentId,
      'Yeni Randevu Oluşturuldu',
      'Diyetisyen $dietitianName ile ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')} tarihinde randevunuz oluşturuldu.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_reminder',
          'Randevu Hatırlatmaları',
          channelDescription: 'Randevu hatırlatma bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    print('Immediate notification sent for new appointment');

    // Benzersiz ID oluştur
    final int uniqueId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Bildirimleri 30 ve 20 dakika önce planla
    await _scheduleNotification(
      id: uniqueId + 1,
      title: 'Randevu Hatırlatması (30 dk)',
      body: 'Diyetisyen $dietitianName ile randevunuza 30 dakika kaldı',
      scheduledTime: appointmentTime.subtract(Duration(minutes: 30)),
    );

    await _scheduleNotification(
      id: uniqueId + 2,
      title: 'Randevu Hatırlatması (20 dk)',
      body: 'Diyetisyen $dietitianName ile randevunuza 20 dakika kaldı',
      scheduledTime: appointmentTime.subtract(Duration(minutes: 20)),
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Skipping notification (ID: $id) because it is in the past');
      return;
    }

    final tz.TZDateTime scheduledTZTime =
        tz.TZDateTime.from(scheduledTime, tz.local);
    print('Scheduling notification ID: $id at $scheduledTZTime');

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_reminder',
          'Randevu Hatırlatmaları',
          channelDescription: 'Randevu hatırlatma bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('Notification scheduled successfully');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
