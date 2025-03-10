import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/client_service.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  ClientDetailScreen({required this.clientId});

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final ClientService _clientService = ClientService();
  Client? client;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final clientData = await _clientService.getClientById(widget.clientId);
      setState(() {
        client = clientData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading client data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danışan Detayları'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : client == null
              ? Center(child: Text('Danışan bilgileri bulunamadı'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      SizedBox(height: 24),
                      _buildSectionTitle('Kişisel Bilgiler'),
                      _buildInfoCard(),
                      SizedBox(height: 24),
                      _buildSectionTitle('Sağlık Bilgileri'),
                      _buildHealthCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              client!.name.isNotEmpty ? client!.name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 40, color: Colors.blue.shade800),
            ),
          ),
          SizedBox(height: 16),
          Text(
            client!.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            client!.email,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Boy', '${client!.height} cm'),
            Divider(),
            _buildInfoRow('Kilo', '${client!.weight} kg'),
            Divider(),
            _buildInfoRow('BMI', '${client!.bmi.toStringAsFixed(2)}'),
            Divider(),
            _buildInfoRow('BMI Durumu', _getBmiStatus(client!.bmi)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alerjiler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            client!.allergies.isEmpty
                ? Text('Bilinen alerji yok',
                    style: TextStyle(fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 8,
                    children: client!.allergies
                        .map((allergy) => Chip(
                              label: Text(allergy),
                              backgroundColor: Colors.red.shade100,
                            ))
                        .toList(),
                  ),
            SizedBox(height: 16),
            Text('Hastalıklar', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            client!.diseases.isEmpty
                ? Text('Bilinen hastalık yok',
                    style: TextStyle(fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 8,
                    children: client!.diseases
                        .map((disease) => Chip(
                              label: Text(disease),
                              backgroundColor: Colors.orange.shade100,
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) {
      return 'Zayıf';
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Fazla Kilolu';
    } else {
      return 'Obez';
    }
  }
}
