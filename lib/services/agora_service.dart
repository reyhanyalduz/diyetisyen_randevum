import 'package:agora_token_service/agora_token_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification_service.dart';

class AgoraService {
  // Your Agora App ID (you need to get this from Agora.io console)
  static const String appId = "7437f7616840417ab2e26e46d5e38206";
  static const String appCertificate = "4c03d8de72ba444899d7e7a89a8119f4";

  // Reference to Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Generate a temporary token for a channel
  String generateToken(String channelName, int uid) {
    // Token süresi (saniye cinsinden)
    int expirationTimeInSeconds = 3600; // 1 saat

    // Token oluştur
    final token = RtcTokenBuilder.build(
      appId: appId,
      appCertificate: appCertificate,
      channelName: channelName,
      uid: uid.toString(),
      role: RtcRole.publisher,
      expireTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          expirationTimeInSeconds,
    );

    return token;
  }

  // Generate a temporary token for a channel
  // In a production environment, your token should be generated on a secure server
  Future<String> createMeeting(String dietitianUid, String clientUid) async {
    try {
      // Generate a channel name based on the users involved - Daha basit bir kanal adı kullan
      String channelName = "${dietitianUid}_${clientUid}";

      print('Creating meeting with channel name: $channelName');

      // Önce mevcut görüşmeleri tamamlanmış olarak işaretle
      await _completeExistingMeetings(dietitianUid, clientUid);

      // Save the meeting details to Firestore
      await _firestore.collection('video_calls').doc(channelName).set({
        'dietitianUid': dietitianUid,
        'clientUid': clientUid,
        'channelName': channelName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'created',
        'dietitianJoined':
            true, // Diyetisyen görüşmeyi başlattığında otomatik olarak katılmış sayılır
        'clientJoined': false,
        'callStartTime': FieldValue.serverTimestamp(),
      });

      // Get dietitian name for notification
      DocumentSnapshot dietitianDoc =
          await _firestore.collection('users').doc(dietitianUid).get();
      if (dietitianDoc.exists) {
        String dietitianName = dietitianDoc['name'] ?? 'Diyetisyen';

        // Send notification to client
        await _notificationService.notifyUserAboutVideoCall(
          receiverUserId: clientUid,
          senderName: dietitianName,
          channelName: channelName,
        );

        print('Notification sent to client: $clientUid');
      }

      return channelName;
    } catch (e) {
      print('Error creating meeting: $e');
      rethrow;
    }
  }

  // Existing meetings'leri tamamlanmış olarak işaretle
  Future<void> _completeExistingMeetings(
      String dietitianUid, String clientUid) async {
    try {
      // Diyetisyen ve danışan arasındaki aktif görüşmeleri bul
      final query = await _firestore
          .collection('video_calls')
          .where('dietitianUid', isEqualTo: dietitianUid)
          .where('clientUid', isEqualTo: clientUid)
          .where('status', isEqualTo: 'created')
          .get();

      // Bulunan görüşmeleri tamamlanmış olarak işaretle
      for (var doc in query.docs) {
        await _firestore.collection('video_calls').doc(doc.id).update({
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Marked existing meeting as completed: ${doc.id}');
      }
    } catch (e) {
      print('Error completing existing meetings: $e');
    }
  }

  // Check if there are active calls for a client
  Future<Map<String, dynamic>?> checkForActiveCall(String uid,
      {bool isDietitian = false}) async {
    try {
      QuerySnapshot query;
      if (isDietitian) {
        query = await _firestore
            .collection('video_calls')
            .where('dietitianUid', isEqualTo: uid)
            .where('status', isEqualTo: 'created')
            .get();
      } else {
        query = await _firestore
            .collection('video_calls')
            .where('clientUid', isEqualTo: uid)
            .where('status', isEqualTo: 'created')
            .where('dietitianJoined',
                isEqualTo: true) // Diyetisyen katılmış olmalı
            .get();
      }

      if (query.docs.isEmpty) return null;

      // En son oluşturulan çağrıyı al
      var docs = query.docs;
      if (docs.length > 1) {
        docs.sort((a, b) {
          var aTime = a['createdAt'] as Timestamp;
          var bTime = b['createdAt'] as Timestamp;
          return bTime.compareTo(aTime); // Descending order
        });
      }

      var doc = docs.first;
      print('Active call found: ${doc.data()}');

      return {
        'channelName': doc['channelName'],
        'dietitianUid': doc['dietitianUid'],
        'clientUid': doc['clientUid'],
        'status': doc['status'],
      };
    } catch (e) {
      print('Error checking for active calls: $e');
      return null;
    }
  }

  // Join an existing meeting
  Future<Map<String, dynamic>?> joinMeeting(String uid,
      {bool isDietitian = false}) async {
    print('JoinMeeting called with uid: $uid, isDietitian: $isDietitian');

    try {
      // Aktif çağrı var mı kontrol et
      var activeCall = await checkForActiveCall(uid, isDietitian: isDietitian);
      if (activeCall == null) {
        print('No active call found for user: $uid');
        return null;
      }

      String channelName = activeCall['channelName'];
      int userUid = isDietitian ? 1 : 2;

      // Token oluştur
      String token = '';
      try {
        token = generateToken(channelName, userUid);
        print('Token generated successfully for channel: $channelName');
      } catch (e) {
        print('Token oluşturma hatası: $e');
        token = '';
      }

      // Update join status
      try {
        String statusField = isDietitian ? 'dietitianJoined' : 'clientJoined';
        print(
            'Updating join status: $statusField = true for channel: $channelName');

        await _firestore
            .collection('video_calls')
            .doc(channelName)
            .update({statusField: true});

        print('Join status updated successfully');
      } catch (e) {
        print('Join status update error: $e');
      }

      return {
        'channelName': channelName,
        'token': token,
        'uid': userUid,
      };
    } catch (e) {
      print('Error in joinMeeting: $e');
      return null;
    }
  }

  // Update meeting status
  Future<void> updateMeetingStatus(String channelName, String status) async {
    await _firestore.collection('video_calls').doc(channelName).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle user leaving the call
  Future<void> handleUserLeave(String channelName, bool isDietitian) async {
    try {
      final docRef = _firestore.collection('video_calls').doc(channelName);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final statusField = isDietitian ? 'dietitianJoined' : 'clientJoined';

        // Update the specific user's join status
        await docRef.update({
          statusField: false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If both users have left, mark the call as completed
        if (!data['dietitianJoined'] && !data['clientJoined']) {
          await docRef.update({
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error handling user leave: $e');
    }
  }

  // Request permissions for camera and microphone
  Future<bool> requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();

    bool cameraGranted = await Permission.camera.isGranted;
    bool microphoneGranted = await Permission.microphone.isGranted;

    return cameraGranted && microphoneGranted;
  }
}
