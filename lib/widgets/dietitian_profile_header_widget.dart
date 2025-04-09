import 'package:flutter/material.dart';
import '../models/user.dart';

class DietitianProfileHeaderWidget extends StatelessWidget {
  final Dietitian dietitian;

  const DietitianProfileHeaderWidget({
    Key? key,
    required this.dietitian,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                dietitian.name.isNotEmpty
                    ? dietitian.name[0].toUpperCase()
                    : '?',
                style: TextStyle(fontSize: 30),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dietitian.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  dietitian.email,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
