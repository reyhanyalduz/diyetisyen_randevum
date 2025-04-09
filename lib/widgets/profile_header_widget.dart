import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Client client;

  const ProfileHeaderWidget({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 50),
            ),
            SizedBox(width: 10),
            Text(
              client.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 10),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
} 