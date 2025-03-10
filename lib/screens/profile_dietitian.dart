import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../screens/add_client_screen.dart';
import '../screens/client_detail_screen.dart';

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
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),floatingActionButton: FloatingActionButton(
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
        backgroundColor: Colors.green,
        child: Icon(Icons.person_add),
        tooltip: 'Danışan Ekle',
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
                    TextButton.icon(
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
                      icon: Icon(Icons.person_add, size: 16),
                      label: Text('Danışan Ekle'),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : '?',
                style: TextStyle(fontSize: 30, color: Colors.green.shade800),
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.user.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.user.email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16),
            if (widget.user is Dietitian) ...[
              Divider(),
              SizedBox(height: 8),
              Row(
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
              SizedBox(height: 8),
              Row(
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade800,
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
                    backgroundColor: Colors.green,
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
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
            title: Text(client.name,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Boy: ${client.height} cm | Kilo: ${client.weight} kg'),
                Text('BMI: ${client.bmi.toStringAsFixed(2)}'),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
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

