import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRViewExample extends StatefulWidget {
  final Function(String) onQrDetected;

  const QRViewExample({required this.onQrDetected, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool hasPermission = false;
  bool isDisposed = false;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!isDisposed && mounted) {
      setState(() {
        hasPermission = status.isGranted;
      });
      if (hasPermission) {
        _initializeCamera();
      }
    }
  }

  void _initializeCamera() {
    setState(() {
      isCameraInitialized = true;
    });
  }

  void _handleQRCode(String? code) {
    if (!isDisposed && mounted && code != null) {
      widget.onQrDetected(code);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _popScreen() {
    if (mounted) {
      controller?.dispose();
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text('QR Kod Tara'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _popScreen,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Kamera izni gerekli',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _checkPermission,
                child: Text('İzin Ver'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _popScreen();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('QR Kod Tara'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _popScreen,
          ),
        ),
        body: Stack(
          children: [
            if (isCameraInitialized)
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ),
              )
            else
              Center(
                child: CircularProgressIndicator(),
              ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'QR kodu çerçeve içine yerleştirin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    if (isDisposed) return;

    this.controller = controller;
    setState(() {
      isCameraInitialized = true;
    });

    controller.resumeCamera(); // Kamerayı başlat
    controller.scannedDataStream.listen((scanData) {
      _handleQRCode(scanData.code);
    });
  }

  @override
  void dispose() {
    isDisposed = true;
    controller?.dispose();
    super.dispose();
  }
}
