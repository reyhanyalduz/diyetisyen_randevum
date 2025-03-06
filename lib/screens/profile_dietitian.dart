import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class DietitianProfileScreen extends StatefulWidget {
  final AppUser user;

  DietitianProfileScreen({required this.user});

  @override
  _DietitianProfileScreenState createState() => _DietitianProfileScreenState();
}

class _DietitianProfileScreenState extends State<DietitianProfileScreen> {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ad: ${widget.user.name}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('E-posta: ${widget.user.email}',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            if (widget.user is Dietitian) ...[
              Text('Uzmanlık Alanı: ${(widget.user as Dietitian).specialty}',
                  style: TextStyle(fontSize: 20)),
            ],
          ],
        ),
      ),
    );
  }
}
