import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diet_plan.dart';
import '../models/user.dart';
import '../screens/video_call_screen.dart';
import '../services/agora_service.dart';
import '../services/auth_service.dart';
import '../services/dietitian_service.dart';
import '../services/pdf_service.dart';
import '../widgets/info_card_widget.dart';
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
  final PdfService _pdfService = PdfService();
  Dietitian? _selectedDietitian;
  List<DietPlan> _dietPlans = [];
  bool _isLoadingDietPlans = false;
  bool _hasActiveCall = false;

  @override
  void initState() {
    super.initState();
    _client = widget.user as Client;
    _loadSelectedDietitian();
    _verifyClientDataConsistency();
    _loadDietPlans();
    _checkForActiveCall();
  }

  Future<void> _loadSelectedDietitian() async {
    try {
      if (_client.dietitianUid != null) {
        print('Attempting to load dietitian with ID: ${_client.dietitianUid}');
        _selectedDietitian =
            await _dietitianService.getDietitianById(_client.dietitianUid!);
        print('Loaded dietitian: ${_selectedDietitian?.name ?? "Not found"}');
        if (mounted) setState(() {});
      } else {
        print('No dietitianUid available to load');
      }
    } catch (e) {
      print('Error loading dietitian: $e');
      // If there's an error, set _selectedDietitian to null to avoid UI issues
      if (mounted) {
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

  // Check for active video calls
  Future<void> _checkForActiveCall() async {
    if (_client.dietitianUid != null) {
      try {
        final activeCall = await _agoraService.checkForActiveCall(_client.uid,
            isDietitian: false);

        setState(() {
          _hasActiveCall = activeCall != null;
        });

        if (_hasActiveCall) {
          print('Active call found: ${activeCall?['channelName']}');
          // Eğer aktif arama varsa, kullanıcıyı bilgilendir
          if (!mounted) return;

          // Eğer diyetisyen henüz katılmamışsa, bilgilendirme mesajı gösterme
          if (activeCall?['dietitianJoined'] == true) {
            _showIncomingCallNotification();
          }
        }
      } catch (e) {
        print('Error checking for active call: $e');
      }
    }
  }

  void _showIncomingCallNotification() {
    // Kullanıcı zaten VideoCall ekranında ise bildirim gösterme
    if (ModalRoute.of(context)?.settings.name == '/videoCall') return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.videocam, color: Colors.white),
            SizedBox(width: 10),
            Text('Diyetisyeninizden bir video araması var!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'CEVAPLA',
          textColor: Colors.white,
          onPressed: _joinVideoCall,
        ),
      ),
    );
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

      await _firestore.collection('clients').doc(_client.uid).update({
        'height': newHeight,
        'weight': newWeight,
      });

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
      // Mevcut diyetisyenlerin listesini al
      final dietitians = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'dietitian')
          .get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Diyetisyen Seç'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dietitians.docs.length,
              itemBuilder: (context, index) {
                final dietitian =
                    AppUser.fromMap(dietitians.docs[index].data()) as Dietitian;
                return ListTile(
                  title: Text(dietitian.name),
                  subtitle: Text(dietitian.specialty),
                  selected: dietitian.uid == _client.dietitianUid,
                  onTap: () async {
                    try {
                      // Update Firebase in both collections
                      await _firestore
                          .collection('clients')
                          .doc(_client.uid)
                          .update({'dietitianUid': dietitian.uid});

                      // Also update the users collection
                      await _firestore
                          .collection('users')
                          .doc(_client.uid)
                          .update({'dietitianUid': dietitian.uid});

                      // Update local client object
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

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Diyetisyen başarıyla güncellendi')),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Diyetisyen güncellenemedi: $e')),
                      );
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diyetisyen listesi yüklenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
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

            // Debug print to check if dietitianUid exists in Firebase data
            print('Firebase client data: $clientData');
            print('DietitianUid from Firebase: ${clientData['dietitianUid']}');

            _client = AppUser.fromMap(clientData) as Client;
            _heightController.text = _client.height.toString();
            _weightController.text = _client.weight.toString();

            // Debug print to check if dietitianUid is properly loaded into the Client object
            print('Client object dietitianUid: ${_client.dietitianUid}');

            // Diyetisyen bilgisini güncelle
            if (_client.dietitianUid != null &&
                (_selectedDietitian?.uid != _client.dietitianUid)) {
              print('Loading dietitian with ID: ${_client.dietitianUid}');
              _loadSelectedDietitian();
            } else if (_client.dietitianUid == null) {
              print(
                  'No dietitian selected, setting _selectedDietitian to null');
              _selectedDietitian = null;
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person, size: 50),
                        ),
                        SizedBox(width: 10),
                        Text('${_client.name}',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                              'VKİ', '${_client.bmi.toStringAsFixed(2)}'),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showMeasurementDialog(),
                            child: InfoCard('Kilo', '${_client.weight} kg'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showMeasurementDialog(),
                            child: InfoCard('Boy', '${_client.height} cm'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TagSection(
                      context: context,
                      title: 'Alerjiler',
                      initialTags: _client.allergies,
                      onTagsUpdated: (tags) =>
                          _updateClientData('allergies', tags),
                    ),
                    TagSection(
                      context: context,
                      title: 'Hastalıklar',
                      initialTags: _client.diseases,
                      onTagsUpdated: (tags) =>
                          _updateClientData('diseases', tags),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      title: Text('Diyetisyen'),
                      subtitle: _selectedDietitian != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedDietitian!.name),
                                Text(_selectedDietitian!.specialty,
                                    style: TextStyle(fontSize: 12)),
                              ],
                            )
                          : Text('Diyetisyen seçilmedi'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner),
                            onPressed: _scanQrCode,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: _changeDietitian,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    //_buildTabSection(),
                    SizedBox(height: 20),
                    _buildDietPlansSection(),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildDietPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Diyet Listeleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _dietPlans.length,
          itemBuilder: (context, index) {
            final dietPlan = _dietPlans[index];
            return _buildDietPlanCard(dietPlan);
          },
        ),
      ],
    );
  }

  Widget _buildDietPlanCard(DietPlan dietPlan) {
    final createdAt = dietPlan.createdAt.toDate();
    final pdfService = PdfService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          title: Text(
            dietPlan.title.isEmpty ? 'Diyet Listesi' : dietPlan.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            DateFormat('dd.MM.yyyy').format(createdAt),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  try {
                    await pdfService.generateDietPlanPdf(dietPlan);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF oluşturulurken bir hata oluştu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMealSection(
                      'Kahvaltı', dietPlan.breakfast, dietPlan.breakfastTime),
                  Divider(height: 24),
                  _buildMealSection(
                      'Öğle Yemeği', dietPlan.lunch, dietPlan.lunchTime),
                  Divider(height: 24),
                  _buildMealSection(
                      'Ara Öğün', dietPlan.snack, dietPlan.snackTime),
                  Divider(height: 24),
                  _buildMealSection(
                      'Akşam Yemeği', dietPlan.dinner, dietPlan.dinnerTime),
                  if (dietPlan.notes.isNotEmpty) ...[
                    Divider(height: 24),
                    Text(
                      'Notlar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      dietPlan.notes,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, String content, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.black87),
        ),
      ],
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
