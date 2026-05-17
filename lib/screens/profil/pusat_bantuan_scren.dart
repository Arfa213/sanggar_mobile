import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'Bagaimana cara mendaftar kegiatan pentas?', 'a': 'Buka menu Event di halaman beranda, pilih event aktif, lalu klik tombol "Ikuti Kegiatan".'},
      {'q': 'Mengapa status keanggotaan saya non-aktif?', 'a': 'Status non-aktif terjadi jika Anda belum menyelesaikan registrasi tahunan atau dikonfirmasi oleh admin sanggar.'},
      {'q': 'Cara mengubah foto profil?', 'a': 'Pada halaman profil utama, klik ikon kamera kecil berwarna emas di pojok kanan bawah foto bulat Anda.'},
    ];

    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        title: const Text('Pusat Bantuan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pertanyaan Sering Diajukan (FAQ)', style: AppText.label.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder2),
                  ),
                  child: ExpansionTile(
                    title: Text(faq['q']!, style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w600, color: kDark)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(faq['a']!, style: AppText.bodySm.copyWith(color: kMuted, height: 1.5)),
                      )
                    ],
                  ),
                )),
            const SizedBox(height: kSpace),
            Container(
              padding: const EdgeInsets.all(kSpace),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPrimary, kPrimaryDark]),
                borderRadius: BorderRadius.circular(kRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masih butuh bantuan lain?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Hubungi langsung kontak resmi Sanggar Mulya Bhakti.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {}, // Hubungkan ke API WhatsApp link jika perlu
                    style: ElevatedButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.white),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: const Text('Hubungi Pengurus Sanggar'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}