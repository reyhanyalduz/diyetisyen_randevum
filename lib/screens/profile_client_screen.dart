import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/dietitian_service.dart';
import '../widgets/diet_list_widget.dart';
import '../widgets/info_card_widget.dart';
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
  Dietitian? _selectedDietitian;

  @override
  void initState() {
    super.initState();
    _client = widget.user as Client;
    _loadSelectedDietitian();
    _verifyClientDataConsistency();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!mounted) return;
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InfoCard('Vücut Kitle İndeksi',
                            '${_client.bmi.toStringAsFixed(2)}'),
                        GestureDetector(
                          onTap: () => _showMeasurementDialog(),
                          child: InfoCard('Kilo', '${_client.weight} kg'),
                        ),
                        GestureDetector(
                          onTap: () => _showMeasurementDialog(),
                          child: InfoCard('Boy', '${_client.height} cm'),
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
                      trailing: Icon(Icons.edit),
                      onTap: _changeDietitian,
                    ),
                    SizedBox(height: 20),
                    //_buildTabSection(),
                    SizedBox(height: 20),
                    BuildDietList(),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
