import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/diet_plan.dart';
import '../models/user.dart';
import '../screens/video_call_screen.dart';
import '../services/agora_service.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../services/diet_plan_service.dart';
import '../utils/constants.dart';
import '../widgets/diet_plan_dialog.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  ClientDetailScreen({required this.clientId});

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final ClientService _clientService = ClientService();
  final DietPlanService _dietPlanService = DietPlanService();
  final AgoraService _agoraService = AgoraService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Client? client;
  bool isLoading = true;
  List<DietPlan> _dietPlans = [];
  bool _isLoadingDietPlans = false;

  @override
  void initState() {
    super.initState();
    _loadClientData();
    _loadDietPlans();
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

  Future<void> _loadDietPlans() async {
    if (mounted) {
      setState(() {
        _isLoadingDietPlans = true;
      });
    }

    try {
      print('Loading diet plans for client: ${widget.clientId}');
      final plans =
          await _dietPlanService.getDietPlansForClient(widget.clientId);

      print(
          'Loaded ${plans.length} diet plans: ${plans.map((p) => p.title).toList()}');

      if (mounted) {
        setState(() {
          _dietPlans = plans;
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

  Future<void> _addOrEditDietPlan(DietPlan? existingPlan) async {
    final currentUser = await AuthService().getCurrentUser();
    if (currentUser == null) return;

    print('Current user: ${currentUser.uid}');

    final result = await showDialog<DietPlan>(
      context: context,
      builder: (context) => DietPlanDialog(
        clientId: widget.clientId,
        dietitianId: currentUser.uid,
        existingPlan: existingPlan,
      ),
    );

    if (result != null) {
      try {
        print(
            'Diet plan to save: ${result.title}, clientId: ${result.clientId}, dietitianId: ${result.dietitianId}');

        if (result.id == null) {
          // Add new diet plan
          final newId = await _dietPlanService.addDietPlan(result);
          print('New diet plan added with ID: $newId');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Diyet planı başarıyla eklendi')),
          );
        } else {
          // Update existing diet plan
          await _dietPlanService.updateDietPlan(result);
          print('Diet plan updated with ID: ${result.id}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Diyet planı başarıyla güncellendi')),
          );
        }
        _loadDietPlans(); // Reload diet plans
      } catch (e) {
        print('Error saving diet plan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız oldu: $e')),
        );
      }
    }
  }

  Future<void> _deleteDietPlan(String dietPlanId) async {
    try {
      await _dietPlanService.deleteDietPlan(dietPlanId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diyet planı başarıyla silindi')),
      );
      _loadDietPlans(); // Reload diet plans
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme işlemi başarısız oldu: $e')),
      );
    }
  }

  // Method to initiate a video call
  Future<void> _initiateVideoCall() async {
    try {
      final currentUser = await AuthService().getCurrentUser();
      if (currentUser == null) return;

      print(
          'Dietitian initiating video call: ${currentUser.uid} to ${widget.clientId}');

      // Create a meeting in Firestore
      final channelName = await _agoraService.createMeeting(
        currentUser.uid,
        widget.clientId,
      );

      print('Meeting created with channel name: $channelName');

      // Explicitly set dietitianJoined to true as the dietitian is initiating
      await _firestore
          .collection('video_calls')
          .doc(channelName)
          .update({'dietitianJoined': true});

      print('Dietitian joined status updated');

      // Navigate to video call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: channelName,
            isDietitian: true,
            uid: currentUser.uid,
          ),
        ),
      );
    } catch (e) {
      print('Error initiating video call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video görüşmesi başlatılamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoading ? 'Danışan Detayları' : '${client?.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call),
            onPressed: _initiateVideoCall,
            tooltip: 'Video Görüşmesi Başlat',
          ),
        ],
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
                      SizedBox(height: 24),
                      _buildDietPlansSection(),
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
            backgroundColor: AppColors.color2.withOpacity(0.1),
            child: Text(
              client!.name.isNotEmpty ? client!.name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 40, color: AppColors.color1),
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
          color: AppColors.color1,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.color1,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
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
    );
  }

  Widget _buildHealthCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.color1,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _buildDietPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diyet Planları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _addOrEditDietPlan(null),
              icon: Icon(Icons.add),
              label: Text('Yeni Plan Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _isLoadingDietPlans
            ? Center(child: CircularProgressIndicator())
            : _dietPlans.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Henüz diyet planı eklenmemiş'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _dietPlans.length,
                    itemBuilder: (context, index) {
                      final plan = _dietPlans[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.color1,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text(plan.title),
                          subtitle: Text(
                              'Oluşturulma: ${_formatDate(plan.createdAt)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: AppColors.color2),
                                onPressed: () => _addOrEditDietPlan(plan),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.red.shade300),
                                onPressed: () =>
                                    _showDeleteConfirmation(plan.id!),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Kahvaltı:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(plan.breakfast),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Saat:'),
                                      ),
                                      Text(plan.breakfastTime),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Öğle Yemeği:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(plan.lunch),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Saat:'),
                                      ),
                                      Text(plan.lunchTime),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Ara Öğün:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(plan.snack),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Saat:'),
                                      ),
                                      Text(plan.snackTime),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Akşam Yemeği:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(plan.dinner),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text('Saat:'),
                                      ),
                                      Text(plan.dinnerTime),
                                    ],
                                  ),
                                  if (plan.notes.isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    Text('Notlar:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 4.0),
                                      child: Text(plan.notes),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ],
    );
  }

  void _showDeleteConfirmation(String dietPlanId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Diyet Planını Sil'),
        content: Text('Bu diyet planını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _deleteDietPlan(dietPlanId);
              Navigator.pop(context);
            },
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
