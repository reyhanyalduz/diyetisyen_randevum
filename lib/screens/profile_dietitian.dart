import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/add_client_screen.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../widgets/clients_list_widget.dart';
import '../widgets/dietitian_profile_header_widget.dart';
import '../widgets/professional_info_widget.dart';
import '../widgets/qr_display_widget.dart';
import '../widgets/qr_scanner_widget.dart';

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
                DietitianProfileHeaderWidget(
                  dietitian: widget.user as Dietitian,
                ),
                if (widget.user is Dietitian) ...[
                  Divider(color: Colors.grey.shade300),
                  SizedBox(height: 8),
                  ProfessionalInfoWidget(
                    dietitian: widget.user as Dietitian,
                    onEdit: _editProfessionalInfo,
                    onExpertiseUpdated: _updateExpertiseAreas,
                  ),
                ],
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Danışanlarım',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRViewExample(
                                    onQrDetected: _handleQrDetected,
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
                ClientsListWidget(
                  clients: clients,
                  isLoading: isLoading,
                  dietitianUid: widget.user.uid,
                  onClientAdded: _loadClients,
                  onQrDetected: _handleQrDetected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleQrDetected(String clientId) async {
    try {
      await _clientService.addClientToDietitian(
        clientId: clientId,
        dietitianId: widget.user.uid,
      );

      if (mounted) {
        _loadClients();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Danışan başarıyla eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _updateExpertiseAreas(List<String> tags) async {
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
          SnackBar(content: Text('Uzmanlık alanları başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme başarısız oldu: $e')),
        );
      }
    }
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
}
