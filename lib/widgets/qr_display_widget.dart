import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRDisplayWidget extends StatelessWidget {
  final String data;
  final String title;
  final bool isDietitian;

  const QRDisplayWidget({
    Key? key,
    required this.data,
    this.title = 'QR Kodum',
    required this.isDietitian,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              isDietitian
                  ? 'Danışanlarınız bu QR kodu taratarak sizi ekleyebilir'
                  : 'Diyetisyeniniz bu QR kodu taratarak sizi ekleyebilir',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
