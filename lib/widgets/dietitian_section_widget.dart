import 'package:flutter/material.dart';

import '../models/user.dart';

class DietitianSectionWidget extends StatelessWidget {
  final Dietitian? selectedDietitian;
  final VoidCallback onQrScan;
  final VoidCallback onChangeDietitian;

  const DietitianSectionWidget({
    Key? key,
    this.selectedDietitian,
    required this.onQrScan,
    required this.onChangeDietitian,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Diyetisyen'),
          subtitle: selectedDietitian != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedDietitian!.name),
                  ],
                )
              : Text('Diyetisyen seçilmedi'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.qr_code_scanner),
                onPressed: onQrScan,
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: onChangeDietitian,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
