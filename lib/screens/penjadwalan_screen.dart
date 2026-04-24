// lib/screens/penjadwalan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/jadwal_pendaftaran.dart';

class PenjadwalanScreen extends StatefulWidget {
  final Tarian? initialTarian;
  const PenjadwalanScreen({super.key, this.initialTarian});
  @override State<PenjadwalanScreen> createState() => _PenjadwalanScreenState();
}

class _PenjadwalanScreenState extends State<PenjadwalanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Tarian>    _tarian       = [];
  List<JadwalLatihan> _jadwal   = [];
  List<Pendaftaran>   _daftar   = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getTarian(),
        ApiService.getJadwal(),
        ApiService.getPendaftaranSaya(),
      ]);
      if (!mounted) return;
      setState(() {
        _tarian  = results[0] as List<Tarian>;
        _jadwal  = results[1] as List<JadwalLatihan>;
        _daftar  = results[2] as List<Pendaftaran>;
        _loading = false;
      });
      // Auto-scroll ke tarian tertentu
      if (widget.initialTarian != null) {
        _tab.animateTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Harus login
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Penjadwalan')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: kPrimaryPale, shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline_rounded, color: kPrimary, size: 36)),
          const SizedBox(height: kSpace),
          Text('Login Diperlukan', style: AppText.displayXs),
          const SizedBox(height: 8),
          const Text('Masuk terlebih dahulu untuk mendaftar kelas tari.',
            style: TextStyle(color: kMuted), textAlign: TextAlign.center),
          const SizedBox(height: kSpaceLg),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Masuk Sekarang')),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: kBgSoft,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true, backgroundColor: kBgCard,
            titleSpacing: 0, toolbarHeight: 64,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const AppBadge('KELAS TARI'),
                Text('Penjadwalan', style: AppText.displaySm),
              ]),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: kPrimary,
              labelColor: kPrimary,
              unselectedLabelColor: kMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Pilih Kelas (${_tarian.length})'),
                Tab(text: 'Terdaftar (${_daftar.length})'),
              ],
            ),
          ),
        ],
        body: _loading ? const AppLoading()
            : _error != null ? AppError(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: kPrimary,
                onRefresh: _load,
                child: TabBarView(controller: _tab, children: [
                  _PilihKelasTab(
                    tarian:         _tarian,
                    jadwal:         _jadwal,
                    daftarSaya:     _daftar,
                    onDaftar:       _daftarKelas,
                    initialTarian:  widget.initialTarian,
                  ),
                  _TerdaftarTab(
                    daftar:     _daftar,
                    onBatalkan: _batalkan,
                  ),
                ]),
              ),
      ),
    );
  }

  Future<void> _daftarKelas(int tarianId, int jadwalId) async {
    try {
      await ApiService.daftarKelas(tarianId: tarianId, jadwalId: jadwalId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Berhasil mendaftar kelas!'),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
        ),
      );
      _tab.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
        ),
      );
    }
  }

  Future<void> _batalkan(int pendaftaranId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLg)),
        title: const Text('Batalkan Pendaftaran?'),
        content: const Text('Kamu akan keluar dari kelas ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.batalkanPendaftaran(pendaftaranId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
}

// ── TAB: PILIH KELAS ──────────────────────────────────────────
class _PilihKelasTab extends StatelessWidget {
  final List<Tarian>       tarian;
  final List<JadwalLatihan> jadwal;
  final List<Pendaftaran>  daftarSaya;
  final Future<void> Function(int, int) onDaftar;
  final Tarian? initialTarian;

  const _PilihKelasTab({
    required this.tarian, required this.jadwal,
    required this.daftarSaya, required this.onDaftar,
    this.initialTarian,
  });

  @override
  Widget build(BuildContext context) {
    final sudahDaftarIds = daftarSaya.map((d) => d.tarianId).toSet();

    return ListView.separated(
      padding: const EdgeInsets.all(kSpace),
      itemCount: tarian.length,
      separatorBuilder: (_, __) => const SizedBox(height: kSpaceSm),
      itemBuilder: (_, i) {
        final t        = tarian[i];
        final sudah    = sudahDaftarIds.contains(t.id);
        final isHilite = initialTarian?.id == t.id;

        return _TarianKelasCard(
          tarian:    t,
          jadwal:    jadwal,
          sudahDaftar: sudah,
          highlighted: isHilite,
          onDaftar:  onDaftar,
        );
      },
    );
  }
}

class _TarianKelasCard extends StatefulWidget {
  final Tarian           tarian;
  final List<JadwalLatihan> jadwal;
  final bool             sudahDaftar;
  final bool             highlighted;
  final Future<void> Function(int, int) onDaftar;
  const _TarianKelasCard({required this.tarian, required this.jadwal,
    required this.sudahDaftar, required this.highlighted, required this.onDaftar});
  @override State<_TarianKelasCard> createState() => _TarianKelasCardState();
}

class _TarianKelasCardState extends State<_TarianKelasCard> {
  bool _expanded = false;
  int? _selectedJadwal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.highlighted;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarian;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(
          color: widget.sudahDaftar ? const Color(0xFF2E7D32)
               : widget.highlighted ? kPrimary
               : kBorder2,
          width: (widget.sudahDaftar || widget.highlighted) ? 1.5 : 1,
        ),
      ),
      child: Column(children: [
        // Header tap
        GestureDetector(
          onTap: widget.sudahDaftar ? null : () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(kSpace),
            child: Row(children: [
              AppImage(
                url: t.foto, width: 60, height: 60,
                borderRadius: BorderRadius.circular(kRadiusSm),
                placeholder: Container(
                  color: kPrimaryPale,
                  child: const Icon(Icons.music_note_rounded, color: kPrimary, size: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.nama, style: AppText.label),
                const SizedBox(height: 3),
                CategoryChip(t.kategori, small: true),
                const SizedBox(height: 3),
                Text('📍 ${t.asal}', style: AppText.bodyXs),
              ])),
              if (widget.sudahDaftar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(kRadiusFull)),
                  child: const Text('✓ Terdaftar',
                    style: TextStyle(color: Color(0xFF2E7D32),
                        fontSize: 11, fontWeight: FontWeight.w800)))
              else
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: kMuted),
            ]),
          ),
        ),

        // Form pilih jadwal
        if (_expanded && !widget.sudahDaftar)
        Container(
          padding: const EdgeInsets.fromLTRB(kSpace, 0, kSpace, kSpace),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppDivider(padding: EdgeInsets.only(bottom: kSpace)),
            Text('Pilih Jadwal Latihan', style: AppText.labelSm),
            const SizedBox(height: kSpaceSm),
            // Jadwal options
            ...widget.jadwal.map((j) => GestureDetector(
              onTap: () => setState(() => _selectedJadwal = j.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedJadwal == j.id ? kPrimaryPale : kBgSoft,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(
                    color: _selectedJadwal == j.id ? kPrimary : kBorder2,
                    width: _selectedJadwal == j.id ? 1.5 : 1)),
                child: Row(children: [
                  Radio<int>(
                    value: j.id, groupValue: _selectedJadwal,
                    onChanged: (v) => setState(() => _selectedJadwal = v),
                    activeColor: kPrimary),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(j.hari, style: AppText.label.copyWith(
                        color: _selectedJadwal == j.id ? kPrimary : kDark)),
                    Text('${j.jamMulai} – ${j.jamSelesai}  ·  ${j.tempat}',
                      style: AppText.bodyXs),
                  ])),
                ]),
              ),
            )).toList(),
            const SizedBox(height: kSpaceSm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedJadwal == null || _loading ? null : () async {
                  setState(() => _loading = true);
                  await widget.onDaftar(widget.tarian.id, _selectedJadwal!);
                  if (mounted) setState(() { _loading = false; _expanded = false; });
                },
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftar Kelas Ini'),
              )),
          ]),
        ),
      ]),
    );
  }
}

// ── TAB: TERDAFTAR ────────────────────────────────────────────
class _TerdaftarTab extends StatelessWidget {
  final List<Pendaftaran> daftar;
  final Future<void> Function(int) onBatalkan;
  const _TerdaftarTab({required this.daftar, required this.onBatalkan});

  @override
  Widget build(BuildContext context) {
    if (daftar.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: kPrimaryPale, borderRadius: BorderRadius.circular(kRadius)),
          child: const Icon(Icons.event_note_rounded, color: kPrimary, size: 32)),
        const SizedBox(height: kSpace),
        Text('Belum ada kelas terdaftar', style: AppText.displayXs.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Pilih kelas tari dari tab "Pilih Kelas"',
            style: TextStyle(color: kMuted)),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(kSpace),
      itemCount: daftar.length,
      separatorBuilder: (_, __) => const SizedBox(height: kSpaceSm),
      itemBuilder: (_, i) {
        final d = daftar[i];
        return Container(
          padding: const EdgeInsets.all(kSpace),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder2)),
          child: Row(children: [
            Container(
              width: 56, height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(kRadiusSm)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(d.hariSingkat, style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.tarianNama, style: AppText.label),
              const SizedBox(height: 3),
              Text('⏰ ${d.jamMulai} – ${d.jamSelesai}',
                  style: AppText.bodyXs),
              Text('📍 ${d.tempat}', style: AppText.bodyXs),
            ])),
            GestureDetector(
              onTap: () => onBatalkan(d.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(color: const Color(0xFFFECACA))),
                child: const Text('Batalkan',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w700))),
            ),
          ]),
        );
      },
    );
  }
}