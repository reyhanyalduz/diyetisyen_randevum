import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/add_client_screen.dart';
import '../screens/client_detail_screen.dart';
import '../utils/constants.dart';

class ClientsListWidget extends StatelessWidget {
  final List<Client> clients;
  final bool isLoading;
  final String dietitianUid;
  final VoidCallback onClientAdded;
  final Function(String) onQrDetected;

  const ClientsListWidget({
    Key? key,
    required this.clients,
    required this.isLoading,
    required this.dietitianUid,
    required this.onClientAdded,
    required this.onQrDetected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                            AddClientScreen(dietitianUid: dietitianUid),
                      ),
                    ).then((result) {
                      if (result == true) {
                        onClientAdded();
                      }
                    });
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Danışan Ekle',
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9.0),
          child: Row(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam Danışan: ',
                  style: TextStyle(color: Colors.grey.shade700)),
              Text(
                '${clients.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.color2.withOpacity(0.1),
                    child: Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : '?',
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
                      Text(
                          'Boy: ${client.height} cm | Kilo: ${client.weight} kg'),
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
                    ).then((_) => onClientAdded());
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
