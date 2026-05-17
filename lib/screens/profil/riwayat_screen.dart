import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy riwayat aktivitas sanggar
    final activities = [
      {'title': 'Mengikuti Latihan Rutin', 'desc': 'Tari Topeng Kelana - Ruang Utama', 'date': 'Hari ini, 16:00'},
      {'title': 'Pendaftaran Event Pentas', 'desc': 'Festival Seni Indramayu 2026', 'date': '14 Mei 2026'},
      {'title': 'Absensi Kehadiran', 'desc': 'Hadir pada kelas Tari Tradisional', 'date': '10 Mei 2026'},
    ];

    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kDark,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(kSpace),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = activities[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: kBorder2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kPrimaryPale, borderRadius: BorderRadius.circular(kRadiusSm)),
                  child: const Icon(Icons.history_toggle_off_rounded, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title']!, style: AppText.label.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(item['desc']!, style: AppText.bodySm.copyWith(color: kMuted)),
                      const SizedBox(height: 6),
                      Text(item['date']!, style: AppText.caption.copyWith(color: kMuted2)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}