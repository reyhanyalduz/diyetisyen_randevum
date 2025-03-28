import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/add_client_screen.dart';
import '../screens/client_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../utils/constants.dart';
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
  List<Client> clients = [];
  bool isLoading = true;

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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                SizedBox(height: 24),
                Row(
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
                                      await _clientService.addClientToDietitian(
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
                                              content:
                                                  Text('Bir hata oluştu: $e')),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Uzmanlık Alanı:',
                      style: TextStyle(color: Colors.grey.shade700)),
                  Text(
                    (widget.user as Dietitian).specialty.isEmpty
                        ? 'Belirtilmemiş'
                        : (widget.user as Dietitian).specialty,
                    style: TextStyle(fontWeight: FontWeight.bold),
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
          ],
        ],
      ),
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
                  label: Text('Danışan Ekle'),
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
