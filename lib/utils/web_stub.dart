// lib/utils/web_stub.dart
import 'package:flutter/material.dart';

class MobileScannerController {
  void dispose() {}
  void stop() {}
  void start() {}
  void toggleTorch() {}
}

class Barcode {
  final String? rawValue;
  Barcode({this.rawValue});
}

class BarcodeCapture {
  final List<Barcode> barcodes;
  BarcodeCapture({required this.barcodes});
}

class MobileScanner extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  const MobileScanner({
    super.key,
    required this.controller,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.orange, size: 64),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Fitur Kamera & Scan Kehadiran tidak didukung di Web / Edge.\nSilakan jalankan aplikasi di Android Emulator atau Device Fisik untuk menggunakan fitur ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Mock a successful detect of a mock token
                onDetect(BarcodeCapture(
                  barcodes: [Barcode(rawValue: "mock_barcode_token_123")],
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Simulasi Scan Sukses (Uji Coba Web)'),
            ),
          ],
        ),
      ),
    );
  }
}
