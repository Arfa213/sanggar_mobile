import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sanggar_mulya_bhakti/main.dart';
import 'package:sanggar_mulya_bhakti/services/auth_provider.dart';

void main() {
  testWidgets('Test loading aplikasi Sanggar', (WidgetTester tester) async {
    // 1. Render aplikasi dengan Provider agar tidak error
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const SanggarApp(),
      ),
    );

    // 2. Karena ada SplashScreen, kita tunggu sebentar
    await tester.pump();

    // 3. Verifikasi apakah judul aplikasi muncul
    // Jika di SplashScreen atau Home ada teks 'Sanggar Mulya Bhakti'
    expect(find.text('Sanggar Mulya Bhakti'), findsOneWidget);
  });
}