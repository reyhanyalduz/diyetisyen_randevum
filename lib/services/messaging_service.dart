import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // FCM izinlerini iste
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // FCM token al
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Yerel bildirimler için kanal oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Önemli Bildirimler',
      description: 'Bu kanal önemli bildirimleri gösterir',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Ön planda bildirim gösterme ayarları
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Arka planda mesaj dinleyicisi
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Ön planda mesaj dinleyicisi
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Custom data kontrolü
      final data = message.data;
      final notificationType = data['type'];
      print('Bildirim türü: $notificationType');
      print('Bildirim verisi: $data');

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              sound: const RawResourceAndroidNotificationSound(
                  'notification_sound'),
              playSound: true,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Uygulama kapalıyken bildirime tıklanma durumu
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Bildirim tıklandı!');
      final data = message.data;
      final notificationType = data['type'];
      print('Tıklanan bildirim türü: $notificationType');
      print('Tıklanan bildirim verisi: $data');
      // Burada bildirime tıklandığında yapılacak işlemleri ekleyebilirsiniz
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

// Arka plan mesaj işleyici
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Arka planda mesaj alındı: ${message.messageId}');
}
