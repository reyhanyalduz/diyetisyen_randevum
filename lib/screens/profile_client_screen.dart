import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/diet_plan.dart';
import '../models/user.dart';
import '../screens/video_call_screen.dart';
import '../services/agora_service.dart';
import '../services/auth_service.dart';
import '../services/dietitian_service.dart';
import '../widgets/diet_plan_widget.dart';
import '../widgets/dietitian_section_widget.dart';
import '../widgets/measurements_section_widget.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/qr_display_widget.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/tag_section_widget.dart';

class ClientProfileScreen extends StatefulWidget {
  final AppUser user;

  ClientProfileScreen({required this.user});

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  late Client _client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final DietitianService _dietitianService = DietitianService();
  final AgoraService _agoraService = AgoraService();
  Dietitian? _selectedDietitian;
  List<DietPlan> _dietPlans = [];
  bool _isLoadingDietPlans = false;
  bool _hasActiveCall = false;
  StreamSubscription? _videoCallSubscription;

  @override
  void initState() {
    super.initState();
    _client = widget.user as Client;
    _loadSelectedDietitian();
    _verifyClientDataConsistency();
    _loadDietPlans();
    _startVideoCallListener();
  }

  void _startVideoCallListener() {
    if (_client.dietitianUid != null) {
      _videoCallSubscription = _firestore
          .collection('video_calls')
          .where('clientUid', isEqualTo: _client.uid)
          .where('status', isEqualTo: 'created')
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;

        if (snapshot.docs.isNotEmpty) {
          final callData = snapshot.docs.first.data();
          setState(() {
            _hasActiveCall = true;
          });

          // Eğer diyetisyen henüz katılmamışsa bildirim göster
          if (callData['dietitianJoined'] == false) {
            _showIncomingCallNotification();
          }
        } else {
          setState(() {
            _hasActiveCall = false;
          });
        }
      });
    }
  }

  Future<void> _loadSelectedDietitian() async {
    if (!mounted) return;

    try {
      if (_client.dietitianUid != null) {
        // Only load if we don't have the dietitian or if it's a different dietitian
        if (_selectedDietitian == null ||
            _selectedDietitian!.uid != _client.dietitianUid) {
          final dietitian =
              await _dietitianService.getDietitianById(_client.dietitianUid!);
          if (mounted && dietitian != null) {
            setState(() {
              _selectedDietitian = dietitian;
            });
          }
        }
      } else if (_selectedDietitian != null) {
        setState(() {
          _selectedDietitian = null;
        });
      }
    } catch (e) {
      print('Error loading dietitian: $e');
      if (mounted && _selectedDietitian != null) {
        setState(() {
          _selectedDietitian = null;
        });
      }
    }
  }

  Future<void> _verifyClientDataConsistency() async {
    try {
      // Check client data in both collections
      final clientDoc =
          await _firestore.collection('clients').doc(_client.uid).get();
      final userDoc =
          await _firestore.collection('users').doc(_client.uid).get();

      if (clientDoc.exists && userDoc.exists) {
        final clientData = clientDoc.data() as Map<String, dynamic>;
        final userData = userDoc.data() as Map<String, dynamic>;

        print('Client collection dietitianUid: ${clientData['dietitianUid']}');
        print('Users collection dietitianUid: ${userData['dietitianUid']}');

        // If there's a mismatch, update the users collection to match clients
        if (clientData['dietitianUid'] != userData['dietitianUid']) {
          print('Fixing inconsistency between collections');
          await _firestore
              .collection('users')
              .doc(_client.uid)
              .update({'dietitianUid': clientData['dietitianUid']});
        }
      }
    } catch (e) {
      print('Error verifying client data consistency: $e');
    }
  }

  Future<void> _loadDietPlans() async {
    if (mounted) {
      setState(() {
        _isLoadingDietPlans = true;
      });
    }

    try {
      final dietPlansSnapshot = await _firestore
          .collection('dietplans')
          .where('clientId', isEqualTo: _client.uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _dietPlans = dietPlansSnapshot.docs
              .map((doc) => DietPlan.fromMap(doc.data(), doc.id))
              .toList();
          _isLoadingDietPlans = false;
        });
      }
    } catch (e) {
      print('Error loading diet plans: $e');
      if (mounted) {
        setState(() {
          _isLoadingDietPlans = false;
        });
      }
    }
  }

  void _showIncomingCallNotification() {
    // Eğer context null ise veya widget ağacına bağlı değilse return
    if (!mounted || context == null) return;

    // Kullanıcı zaten VideoCall ekranında ise bildirim gösterme
    if (ModalRoute.of(context)?.settings.name == '/videoCall') return;

    // BuildContext'in geçerli olduğundan emin olmak için Future.microtask kullan
    Future.microtask(() {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.videocam, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: const Text('Diyetisyeninizden bir video araması var!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 20),
          action: SnackBarAction(
            label: 'CEVAPLA',
            textColor: Colors.white,
            onPressed: _joinVideoCall,
          ),
        ),
      );
    });
  }

  // Method to join a video call
  Future<void> _joinVideoCall() async {
    try {
      final activeCall = await _agoraService.checkForActiveCall(_client.uid,
          isDietitian: false);

      if (activeCall == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktif görüşme bulunamadı.')),
        );
        return;
      }

      final meetingDetails = await _agoraService.joinMeeting(
        _client.uid,
        isDietitian: false,
      );

      if (meetingDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: meetingDetails['channelName'],
              isDietitian: false,
              uid: _client.uid,
            ),
            settings: RouteSettings(name: '/videoCall'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görüşme başlatılamadı.')),
        );
      }
    } catch (e) {
      print('Error joining video call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video görüşmesine katılınamadı: $e')),
      );
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _videoCallSubscription?.cancel(); // Stream'i temizle
    super.dispose();
  }

  Future<void> _updateClientData(String field, List<String> values) async {
    try {
      await _firestore.collection('clients').doc(_client.uid).update({
        field: values,
      });
      setState(() {
        if (field == 'allergies') {
          _client = Client(
            uid: _client.uid,
            name: _client.name,
            email: _client.email,
            height: _client.height,
            weight: _client.weight,
            allergies: values,
            diseases: _client.diseases,
          );
        } else if (field == 'diseases') {
          _client = Client(
            uid: _client.uid,
            name: _client.name,
            email: _client.email,
            height: _client.height,
            weight: _client.weight,
            allergies: _client.allergies,
            diseases: values,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız oldu: $e')),
      );
    }
  }

  Future<void> _updateMeasurements() async {
    try {
      int newHeight = int.tryParse(_heightController.text) ?? _client.height;
      double newWeight =
          double.tryParse(_weightController.text) ?? _client.weight;

      if (newHeight < 100 || newHeight > 250) {
        throw 'Boy 100-250 cm arasında olmalıdır';
      }
      if (newWeight < 30 || newWeight > 300) {
        throw 'Kilo 30-300 kg arasında olmalıdır';
      }

      // VKİ hesaplama
      double newBMI = newWeight / ((newHeight / 100) * (newHeight / 100));

      // Batch işlemi başlat
      WriteBatch batch = _firestore.batch();

      // Kullanıcı bilgilerini güncelle
      batch.update(_firestore.collection('clients').doc(_client.uid), {
        'height': newHeight,
        'weight': newWeight,
      });

      // VKİ geçmişine yeni kayıt ekle
      batch.set(
        _firestore.collection('bmi_history').doc(),
        {
          'clientId': _client.uid,
          'height': newHeight,
          'weight': newWeight,
          'bmi': newBMI,
          'date': FieldValue.serverTimestamp(),
        },
      );

      // Batch işlemini gerçekleştir
      await batch.commit();

      setState(() {
        _client = Client(
          uid: _client.uid,
          name: _client.name,
          email: _client.email,
          height: newHeight,
          weight: newWeight,
          allergies: _client.allergies,
          diseases: _client.diseases,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ölçüler başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız oldu: $e')),
      );
    }
  }

  void _showMeasurementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ölçüleri Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Boy (cm)',
                hintText: '100-250 cm arası',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilo (kg)',
                hintText: '30-300 kg arası',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _updateMeasurements();
              Navigator.pop(context);
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeDietitian() async {
    try {
      final dietitians = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'dietitian')
          .get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Diyetisyen Seç'),
          content: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dietitians.docs.length,
              itemBuilder: (context, index) {
                final dietitian =
                    AppUser.fromMap(dietitians.docs[index].data()) as Dietitian;
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: Row(
                            children: [
                              CircleAvatar(
                                child: Icon(Icons.person),
                                radius: 25,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  dietitian.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildInfoSection('Hakkında', dietitian.about),
                                SizedBox(height: 16),
                                _buildInfoSection(
                                    'Eğitim', dietitian.education),
                                SizedBox(height: 16),
                                _buildInfoSection(
                                    'Deneyim', dietitian.experience),
                                if (dietitian.expertiseAreas.isNotEmpty) ...[
                                  SizedBox(height: 16),
                                  _buildInfoSection('Uzmanlık Alanları',
                                      dietitian.expertiseAreas.join(', ')),
                                ],
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Geri'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _firestore
                                      .collection('clients')
                                      .doc(_client.uid)
                                      .update({'dietitianUid': dietitian.uid});

                                  await _firestore
                                      .collection('users')
                                      .doc(_client.uid)
                                      .update({'dietitianUid': dietitian.uid});

                                  setState(() {
                                    _client = Client(
                                      uid: _client.uid,
                                      name: _client.name,
                                      email: _client.email,
                                      height: _client.height,
                                      weight: _client.weight,
                                      allergies: _client.allergies,
                                      diseases: _client.diseases,
                                      dietitianUid: dietitian.uid,
                                    );
                                    _selectedDietitian = dietitian;
                                  });

                                  Navigator.of(context)
                                      .pop(); // Close detail dialog
                                  Navigator.of(context)
                                      .pop(); // Close selection dialog

                                  // Reload the dietitian information to ensure it's up to date
                                  await _loadSelectedDietitian();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Diyetisyen başarıyla seçildi')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Diyetisyen seçilemedi: $e')),
                                  );
                                }
                              },
                              child: Text('Seç'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 25,
                      ),
                      title: Text(
                        dietitian.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diyetisyen listesi yüklenemedi: $e')),
      );
    }
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profilim'),
        actions: [
          if (_selectedDietitian != null && _hasActiveCall)
            IconButton(
              icon: Icon(Icons.video_call, color: Colors.red),
              onPressed: _joinVideoCall,
              tooltip: 'Video Görüşmesine Katıl',
            ),
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRDisplayWidget(
                    data: _client.uid,
                    isDietitian: false,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('clients').doc(_client.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No data available'));
            }

            var clientData = snapshot.data!.data() as Map<String, dynamic>;

            // Update client data only if it has changed
            if (_client.uid != clientData['uid'] ||
                _client.height != clientData['height'] ||
                _client.weight != clientData['weight'] ||
                _client.dietitianUid != clientData['dietitianUid']) {
              _client = AppUser.fromMap(clientData) as Client;
              _heightController.text = _client.height.toString();
              _weightController.text = _client.weight.toString();

              // Load dietitian information when client data changes
              _loadSelectedDietitian();
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeaderWidget(client: _client),
                    MeasurementsSectionWidget(
                      client: _client,
                      onMeasurementTap: _showMeasurementDialog,
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TagSection(
                        context: context,
                        title: 'Alerjiler',
                        initialTags: _client.allergies,
                        onTagsUpdated: (tags) =>
                            _updateClientData('allergies', tags),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TagSection(
                        context: context,
                        title: 'Hastalıklar',
                        initialTags: _client.diseases,
                        onTagsUpdated: (tags) =>
                            _updateClientData('diseases', tags),
                      ),
                    ),
                    SizedBox(height: 20),
                    DietitianSectionWidget(
                      selectedDietitian: _selectedDietitian,
                      onQrScan: _scanQrCode,
                      onChangeDietitian: _changeDietitian,
                    ),
                    SizedBox(height: 20),
                    DietPlanWidget(
                      clientId: _client.uid,
                      isProfileView: true,
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  void _scanQrCode() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRViewExample(
            onQrDetected: (String dietitianId) async {
              // QR kod okunduğunda
              try {
                await _firestore
                    .collection('clients')
                    .doc(_client.uid)
                    .update({'dietitianUid': dietitianId});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Diyetisyen başarıyla eklendi')),
                );

                // Profil bilgilerini güncelle
                _loadSelectedDietitian();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bir hata oluştu: $e')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR kod taranamadı: $e')),
      );
    }
  }
}
