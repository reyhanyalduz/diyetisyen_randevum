import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../services/auth_service.dart';

// This function must be top-level (not nested in a class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // You can also handle the message here if needed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await _notifications.initialize(settings);
    print('Notification service initialized successfully');

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('WARNING: Notification permissions were denied');
        // TODO: Show a dialog explaining why notifications are important
      }

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token == null) {
        print('ERROR: Failed to get FCM token');
        return;
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        _handleMessage(message);
      });

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) async {
        print('FCM Token refreshed: $token');
        final currentUser = await AuthService().getCurrentUser();
        if (currentUser != null) {
          await saveToken(currentUser.uid);
        }
      });

      // Set foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('ERROR initializing Firebase Messaging: $e');
    }
  }

  Future<void> saveToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('Saving FCM token for user $userId: $token');
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'notificationsEnabled': true,
        });
      } else {
        print('ERROR: Failed to get FCM token for saving');
      }
    } catch (e) {
      print('ERROR saving FCM token: $e');
    }
  }

  // Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    print('Got a message: ${message.notification?.title}');
    print('Message data: ${message.data}');

    // Check if it's a video call notification
    if (message.data['type'] == 'video_call') {
      showVideoCallNotification(
        title: message.notification?.title ?? 'Gelen Video Görüşmesi',
        body: message.notification?.body ?? 'Biri sizinle görüşmek istiyor',
        channelName: message.data['channelName'],
      );
    }
  }

  // Show a video call notification
  Future<void> showVideoCallNotification({
    required String title,
    required String body,
    required String channelName,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'video_call_channel',
        'Video Call Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'notification_sound.aiff',
        ),
      );

      await _notifications.show(
        1,
        title,
        body,
        platformChannelSpecifics,
        payload: channelName,
      );
      print('Local notification shown successfully');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Method to notify a user about a video call
  Future<void> notifyUserAboutVideoCall({
    required String receiverUserId,
    required String senderName,
    required String channelName,
  }) async {
    print('\n=== NOTIFICATION SERVICE DEBUG ===');
    print('notifyUserAboutVideoCall STARTED');
    print('Parameters:');
    print('- receiverUserId: $receiverUserId');
    print('- senderName: $senderName');
    print('- channelName: $channelName');

    try {
      // Get receiver's document
      final receiverDoc =
          await _firestore.collection('users').doc(receiverUserId).get();
      print('Receiver document exists: ${receiverDoc.exists}');

      if (!receiverDoc.exists) {
        print('ERROR: Receiver document not found');
        return;
      }

      final receiverData = receiverDoc.data();
      print('Receiver data: $receiverData');

      // Check if notifications are enabled
      final notificationsEnabled =
          receiverData?['notificationsEnabled'] ?? true;
      if (!notificationsEnabled) {
        print('WARNING: Notifications are disabled for this user');
        return;
      }

      final receiverToken = receiverData?['fcmToken'];
      print('Receiver FCM token: $receiverToken');

      if (receiverToken == null) {
        print('ERROR: No FCM token found for receiver');
        return;
      }

      // Show local notification
      await showVideoCallNotification(
        title: 'Gelen Video Görüşmesi',
        body: '$senderName sizinle görüşmek istiyor',
        channelName: channelName,
      );
      print('Local notification shown successfully');

      // TODO: Implement FCM notification sending through your backend server
      // For now, we're only showing local notifications
    } catch (e) {
      print('ERROR in notifyUserAboutVideoCall: $e');
    }
    print('=== NOTIFICATION SERVICE DEBUG END ===\n');
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
