import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../services/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final bool isDietitian;
  final String uid;

  const VideoCallScreen({
    Key? key,
    required this.channelName,
    required this.isDietitian,
    required this.uid,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraService _agoraService = AgoraService();
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _muted = false;
  bool _videoDisabled = false;
  int? _localUid;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  @override
  void dispose() {
    try {
      // Kullanıcı görüşmeden ayrılırken durumu güncelle
      _agoraService.handleUserLeave(widget.channelName, widget.isDietitian);

      // clear users
      _engine.leaveChannel();
      _engine.release();
    } catch (e) {
      print('Error in dispose: $e');
    }
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    try {
      // retrieve permissions
      await _agoraService.requestPermissions();

      // Get meeting details
      final meetingDetails = await _agoraService.joinMeeting(
        widget.uid,
        isDietitian: widget.isDietitian,
      );

      print('Meeting details received: $meetingDetails');

      if (meetingDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görüşme bulunamadı')),
        );
        Navigator.pop(context);
        return;
      }

      setState(() {
        _localUid = meetingDetails['uid'];
      });

      // Debug için
      print('Video call parameters:');
      print('Channel Name: ${widget.channelName}');
      print('Local UID: $_localUid');
      print('Is Dietitian: ${widget.isDietitian}');

      // Create RTC engine instance
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: AgoraService.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print(
                'Local user joined successfully - Channel: ${connection.channelId}, UID: ${connection.localUid}');
            setState(() {
              _localUserJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print(
                'Remote user joined: $remoteUid in channel: ${connection.channelId}');
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print('Remote user left: $remoteUid, reason: $reason');
            setState(() {
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora Error: code=$err, message=$msg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bağlantı hatası: $err - $msg')),
            );

            // Error handling for specific errors
            if (err == ErrorCodeType.errInvalidChannelName) {
              print(
                  'Invalid channel name. Please check the channel name format');
            } else if (err == ErrorCodeType.errInvalidToken) {
              print('Invalid token. Please check if the token is valid');
            }
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state, ConnectionChangedReasonType reason) {
            print('Connection state changed: $state, reason: $reason');

            if (state == ConnectionStateType.connectionStateConnected) {
              print('Successfully connected to the channel');
            }
          },
        ),
      );

      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableVideo();
      await _engine.startPreview();

      try {
        String token = meetingDetails['token'] ?? '';
        print(
            'Joining channel with: channelId=${widget.channelName}, uid=$_localUid, token=$token');
        await _engine.joinChannel(
          token: token,
          channelId: widget.channelName,
          uid: _localUid ?? 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
            publishMicrophoneTrack: true,
            publishCameraTrack: true,
          ),
        );
        print('Join channel request sent successfully');
      } catch (e) {
        print('Error joining channel: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kanala katılırken hata: $e')),
        );
      }
    } catch (e) {
      print('Error in _initializeAgora: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video görüşmesi başlatılamadı: $e')),
      );
      Navigator.pop(context);
    }
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Görüşmesi'),
      ),
      body: Stack(
        children: [
          Center(
            child: _renderRemoteVideo(),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 120,
              height: 160,
              margin: const EdgeInsets.only(top: 10, right: 10),
              child: _renderLocalPreview(),
            ),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  // Local preview
  Widget _renderLocalPreview() {
    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  // Remote preview
  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Diğer kullanıcı bekleniyor...',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      );
    }
  }

  // Toolbar with mute, video toggle and end call buttons
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? Colors.redAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.white : Colors.black,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: _onToggleVideoDisabled,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _videoDisabled ? Colors.redAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _videoDisabled ? Icons.videocam_off : Icons.videocam,
              color: _videoDisabled ? Colors.white : Colors.black,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  void _onToggleVideoDisabled() async {
    try {
      setState(() {
        _videoDisabled = !_videoDisabled;
      });

      if (_videoDisabled) {
        // Sadece kamerayı devre dışı bırak
        await _engine.muteLocalVideoStream(true);
        await _engine.enableLocalVideo(false);
      } else {
        // Sadece kamerayı etkinleştir
        await _engine.muteLocalVideoStream(false);
        await _engine.enableLocalVideo(true);
      }
    } catch (e) {
      print('Error toggling video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera durumu değiştirilemedi: $e')),
      );
    }
  }

  void _onCallEnd(BuildContext context) {
    _agoraService.updateMeetingStatus(widget.channelName, 'completed');
    Navigator.pop(context);
  }
}
