import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/add_client_screen.dart';
import '../screens/client_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../utils/constants.dart';
import '../widgets/qr_display_widget.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/tag_section_widget.dart';

class DietitianProfileScreen extends StatefulWidget {
  final AppUser user;

  DietitianProfileScreen({required this.user});

  @override
  _DietitianProfileScreenState createState() => _DietitianProfileScreenState();
}

class _DietitianProfileScreenState extends State<DietitianProfileScreen> {
  final ClientService _clientService = ClientService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Client> clients = [];
  bool isLoading = true;
  bool _isEditingExpertise = false;
  TextEditingController _newExpertiseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      isLoading = true;
    });

    try {
      final clientList =
          await _clientService.getClientsForDietitian(widget.user.uid);
      setState(() {
        clients = clientList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading clients: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRDisplayWidget(
                    data: widget.user.uid,
                    isDietitian: true,
                  ),
                ),
              );
            },
          ),
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
      body: RefreshIndicator(
        onRefresh: _loadClients,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Danışanlarım'),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRViewExample(
                                    onQrDetected: (String clientId) async {
                                      try {
                                        await _clientService
                                            .addClientToDietitian(
                                          clientId: clientId,
                                          dietitianId: widget.user.uid,
                                        );

                                        if (mounted) {
                                          _loadClients();
                                        }

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Danışan başarıyla eklendi')),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Bir hata oluştu: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddClientScreen(
                                      dietitianUid: widget.user.uid),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadClients();
                                }
                              });
                            },
                            icon: Icon(Icons.person_add, size: 16),
                            label: Text('Danışan Ekle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Toplam Danışan:',
                          style: TextStyle(color: Colors.grey.shade700)),
                      Text(
                        '${clients.length}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                _buildClientsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return  Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(fontSize: 30),
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          if (widget.user is Dietitian) ...[
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 8),
            _buildProfessionalInfo(),
            SizedBox(height: 8),
          ],
        ],
    );
  }

  Widget _buildProfessionalInfo() {
    final dietitian = widget.user as Dietitian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hakkımda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: _editProfessionalInfo,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (dietitian.about.isNotEmpty) ...[
                  Text(
                    dietitian.about,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (dietitian.experience.isNotEmpty) ...[
                  Text(
                    'Deneyim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dietitian.experience,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 16),
                ],
                if (dietitian.education.isNotEmpty) ...[
                  Text(
                    'Eğitim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dietitian.education,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TagSection(
              context: context,
              title: 'Uzmanlık Alanları',
              initialTags: (widget.user as Dietitian).expertiseAreas,
              onTagsUpdated: (tags) async {
                try {
                  final updatedDietitian = Dietitian(
                    uid: (widget.user as Dietitian).uid,
                    name: (widget.user as Dietitian).name,
                    email: (widget.user as Dietitian).email,
                    specialty: (widget.user as Dietitian).specialty,
                    experience: (widget.user as Dietitian).experience,
                    education: (widget.user as Dietitian).education,
                    about: (widget.user as Dietitian).about,
                    expertiseAreas: tags,
                  );
                  await Future.wait([
                    _firestore
                        .collection('users')
                        .doc(updatedDietitian.uid)
                        .update(updatedDietitian.toMap()),
                    _firestore
                        .collection('dietitians')
                        .doc(updatedDietitian.uid)
                        .update(updatedDietitian.toMap()),
                  ]);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Uzmanlık alanları başarıyla güncellendi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Güncelleme başarısız oldu: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _editProfessionalInfo() async {
    final dietitian = widget.user as Dietitian;
    final formKey = GlobalKey<FormState>();
    final specialtyController =
        TextEditingController(text: dietitian.specialty);
    final experienceController =
        TextEditingController(text: dietitian.experience);
    final educationController =
        TextEditingController(text: dietitian.education);
    final aboutController = TextEditingController(text: dietitian.about);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Profesyonel Bilgileri Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: aboutController,
                    decoration: InputDecoration(labelText: 'Hakkımda'),
                  ),
                  TextFormField(
                    controller: experienceController,
                    decoration: InputDecoration(labelText: 'Deneyim'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: educationController,
                    decoration: InputDecoration(labelText: 'Eğitim'),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final updatedDietitian = Dietitian(
                      uid: dietitian.uid,
                      name: dietitian.name,
                      email: dietitian.email,
                      specialty: specialtyController.text,
                      experience: experienceController.text,
                      education: educationController.text,
                      about: aboutController.text,
                      expertiseAreas: dietitian.expertiseAreas,
                    );

                    // Update both collections to ensure consistency
                    await Future.wait([
                      _firestore
                          .collection('users')
                          .doc(dietitian.uid)
                          .update(updatedDietitian.toMap()),
                      _firestore
                          .collection('dietitians')
                          .doc(dietitian.uid)
                          .update(updatedDietitian.toMap()),
                    ]);

                    if (mounted) {
                      Navigator.pop(context);
                      // Rebuild the widget with updated data
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DietitianProfileScreen(user: updatedDietitian),
                        ),
                        (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Bilgiler başarıyla güncellendi')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Güncelleme başarısız oldu: $e')),
                      );
                    }
                  }
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (clients.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Henüz danışanınız bulunmamaktadır',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddClientScreen(dietitianUid: widget.user.uid),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadClients();
                      }
                    });
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Danışan Ekle ',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.color1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: AppColors.color2.withOpacity(0.3),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.color2.withOpacity(0.1),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: TextStyle(color: AppColors.color1),
              ),
            ),
            title: Text(
              client.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Boy: ${client.height} cm | Kilo: ${client.weight} kg'),
                Text(
                  'BMI: ${client.bmi.toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.color1),
                ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.color2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClientDetailScreen(clientId: client.uid),
                ),
              ).then((_) => _loadClients());
            },
          ),
        );
      },
    );
  }
}
