// lib/screens/profil/riwayat_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});
  @override State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<Kehadiran> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _data = await ApiService.getKehadiranSaya();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: kBgCard, foregroundColor: kDark, elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder)),
      ),
      body: _loading
          ? const AppLoading()
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : _data.isEmpty
                  ? const Center(child: Text('Belum ada riwayat kehadiran.'))
                  : RefreshIndicator(color: kPrimary, onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(kSpace),
                        itemCount: _data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _KehadiranCard(_data[i]),
                      )),
    );
  }
}

class _KehadiranCard extends StatelessWidget {
  final Kehadiran k;
  const _KehadiranCard(this.k);
  @override
  Widget build(BuildContext context) {
    final colors = {
      'hadir': [const Color(0xFFE8F5E9), const Color(0xFF2E7D32)],
      'izin':  [const Color(0xFFFFF3E0), const Color(0xFFE65100)],
      'alpa':  [const Color(0xFFFEF2F2), const Color(0xFFDC2626)],
    };
    final icons  = {'hadir': '✓', 'izin': '~', 'alpa': '✗'};
    final labels = {'hadir': 'Hadir', 'izin': 'Izin', 'alpa': 'Alpa'};
    final c = colors[k.status] ?? [kBorder, kMuted];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(icons[k.status] ?? '?',
              style: TextStyle(color: c[1], fontWeight: FontWeight.w900, fontSize: 16)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k.tarianNama, style: AppText.label),
          const SizedBox(height: 3),
          Text(k.tanggalFormatted, style: AppText.bodyXs),
          if (k.jadwal != null)
            Text('${k.jadwal!.hari} · ${k.jadwal!.jamMulai}–${k.jadwal!.jamSelesai}', style: AppText.bodyXs),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(kRadiusFull)),
          child: Text(labels[k.status] ?? k.status,
              style: TextStyle(color: c[1], fontSize: 11, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}