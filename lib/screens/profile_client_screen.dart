import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _client = widget.user as Client;
    _heightController.text = _client.height.toString();
    _weightController.text = _client.weight.toString();
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
      body: SingleChildScrollView(
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
                      //${user.name}',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                onTagsUpdated: (tags) => _updateClientData('allergies', tags),
              ),
              TagSection(
                context: context,
                title: 'Hastalıklar',
                initialTags: _client.diseases,
                onTagsUpdated: (tags) => _updateClientData('diseases', tags),
              ),
              SizedBox(height: 20),
              //_buildTabSection(),
              SizedBox(height: 20),
              BuildDietList(),
            ],
          ),
        ),
      ),
    );
  }
}
