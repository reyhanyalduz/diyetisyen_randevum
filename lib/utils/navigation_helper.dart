import 'package:flutter/material.dart';
import '../screens/video_call_screen.dart';

extension NavigationHelper on BuildContext {
  // Navigate to video call screen directly
  Future<dynamic> navigateToVideoCall({
    required String channelName,
    required bool isDietitian,
    required String uid,
  }) {
    return Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelName: channelName,
          isDietitian: isDietitian,
          uid: uid,
        ),
      ),
    );
  }

  // Navigate to video call using named route
  Future<dynamic> navigateToVideoCallNamed({
    required String channelName,
    required bool isDietitian,
    required String uid,
  }) {
    return Navigator.pushNamed(
      this,
      '/videoCall',
      arguments: {
        'channelName': channelName,
        'isDietitian': isDietitian,
        'uid': uid,
      },
    );
  }
}
