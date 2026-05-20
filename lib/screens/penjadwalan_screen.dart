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
        ApiService.getPendaftaranSayaRaw(),
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
        appBar: AppBar(title: Text('Penjadwalan')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: kPrimaryPale, shape: BoxShape.circle),
            child: Icon(Icons.lock_outline_rounded, color: kPrimary, size: 36)),
          SizedBox(height: kSpace),
          Text('Login Diperlukan', style: AppText.displayXs),
          SizedBox(height: 8),
          Text('Masuk terlebih dahulu untuk mendaftar kelas tari.',
            style: TextStyle(color: kMuted), textAlign: TextAlign.center),
          SizedBox(height: kSpaceLg),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('Masuk Sekarang')),
        ])),
      );
    }

    final isPengunjung = auth.user?.isPengunjung == true;

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
                AppBadge(isPengunjung ? 'BOOKING SESI' : 'KELAS TARI'),
                Text(isPengunjung ? 'Sesi Latihan' : 'Penjadwalan', style: AppText.displaySm),
              ]),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: kSpace, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kBgSoft,
                  borderRadius: BorderRadius.circular(kRadiusFull),
                  border: Border.all(color: kBorder2),
                ),
                child: TabBar(
                  controller: _tab,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(kRadiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: kMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  tabs: [
                    Tab(text: isPengunjung ? 'Pilih Tarian (${_tarian.length})' : 'Pilih Kelas (${_tarian.length})'),
                    Tab(text: isPengunjung ? 'Booking Saya (${_daftar.length})' : 'Terdaftar (${_daftar.length})'),
                  ],
                ),
              ),
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

  Future<void> _daftarKelas({
    required int tarianId,
    int? jadwalId,
    String? tanggal,
    String? jam,
    String? catatan,
  }) async {
    try {
      if (jadwalId != null) {
        await ApiService.daftarKelas(tarianId: tarianId, jadwalId: jadwalId, catatan: catatan);
      } else {
        await ApiService.daftarKelas(
          tarianId: tarianId,
          tanggalLatihan: tanggal,
          jamLatihan: jam,
          catatan: catatan,
        );
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(jadwalId != null ? 'Berhasil mendaftar kelas!' : 'Booking berhasil dikirim!'),
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
        title: Text('Batalkan Pendaftaran?'),
        content: Text('Kamu akan keluar dari kelas ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Tidak')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Ya, Batalkan')),
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
  final Future<void> Function({
    required int tarianId,
    int? jadwalId,
    String? tanggal,
    String? jam,
    String? catatan,
  }) onDaftar;
  final Tarian? initialTarian;

  const _PilihKelasTab({
    required this.tarian, required this.jadwal,
    required this.daftarSaya, required this.onDaftar,
    this.initialTarian,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPengunjung = auth.user?.isPengunjung == true;
    final sudahDaftarIds = isPengunjung ? <int>{} : daftarSaya.map((d) => d.tarianId).toSet();

    return ListView.separated(
      padding: const EdgeInsets.all(kSpace),
      itemCount: tarian.length,
      separatorBuilder: (_, __) => SizedBox(height: kSpaceSm),
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
  final Future<void> Function({
    required int tarianId,
    int? jadwalId,
    String? tanggal,
    String? jam,
    String? catatan,
  }) onDaftar;
  const _TarianKelasCard({required this.tarian, required this.jadwal,
    required this.sudahDaftar, required this.highlighted, required this.onDaftar});
  @override State<_TarianKelasCard> createState() => _TarianKelasCardState();
}

class _TarianKelasCardState extends State<_TarianKelasCard> {
  bool _expanded = false;
  int? _selectedJadwal;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final _catatanController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.highlighted;
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarian;
    final auth = context.watch<AuthProvider>();
    final isPengunjung = auth.user?.isPengunjung == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(
          color: widget.sudahDaftar ? const Color(0xFF2E7D32)
               : widget.highlighted ? kPrimary
               : kBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.highlighted 
                ? kPrimary.withOpacity(0.06)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadius - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLEAN SOOTHING COVER IMAGE (NO HARSH GRADIENTS)
            Hero(
              tag: 'tarian_cover_${t.id}',
              child: AppImage(
                url: t.foto,
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.zero,
                placeholder: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryPale, kPrimaryPale2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.music_note_rounded, color: kPrimary.withOpacity(0.4), size: 32),
                  ),
                ),
              ),
            ),
            
            // CARD BODY (EASY TO READ & BREATHABLE)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORY & LOCATION (SOFT & TASTEFUL)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimaryPale,
                          borderRadius: BorderRadius.circular(kRadiusXs),
                        ),
                        child: Text(
                          t.kategori.toUpperCase(),
                          style: TextStyle(
                            color: kPrimary, 
                            fontSize: 9, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📍 ${t.asal}',
                        style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (widget.sudahDaftar)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(kRadiusXs),
                          ),
                          child: const Text(
                            '✓ Terdaftar',
                            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // TITLE & ACTION ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          t.nama,
                          style: AppText.displaySm.copyWith(fontSize: 18, color: kDark),
                        ),
                      ),
                      if (!widget.sudahDaftar)
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _expanded ? kPrimary : kPrimaryPale,
                              borderRadius: BorderRadius.circular(kRadiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _expanded ? 'Tutup' : (isPengunjung ? 'Booking' : 'Daftar'),
                                  style: TextStyle(
                                    color: _expanded ? Colors.white : kPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                  color: _expanded ? Colors.white : kPrimary,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // EXPANDED FORM (CLEAN & MINIMALIST)
                  if (_expanded && !widget.sudahDaftar) ...[
                    const SizedBox(height: 16),
                    const AppDivider(),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBgSoft,
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        border: Border.all(color: kBorder2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPengunjung) ...[
                            // ── Visitor Dynamic Booking Form ──
                            Text('Tanggal Booking', style: AppText.label),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: kPrimary,
                                          onPrimary: Colors.white,
                                          onSurface: kDark,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(kRadiusXs),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: kPrimary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedDate == null
                                          ? 'Ketuk untuk pilih tanggal...'
                                          : _formatDate(_selectedDate!),
                                      style: TextStyle(
                                        color: _selectedDate == null ? kMuted : kDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Text('Pilih Jam Booking', style: AppText.label),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                '08:00', '09:00', '10:00', '11:00', 
                                '13:00', '14:00', '15:00', '16:00', 
                                '17:00', '18:00', '19:00', '20:00'
                              ].map((slot) {
                                final isSelected = _selectedTimeSlot == slot;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedTimeSlot = slot),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? kPrimary : Colors.white,
                                      borderRadius: BorderRadius.circular(kRadiusXs),
                                      border: Border.all(
                                        color: isSelected ? kPrimary : kBorder,
                                      ),
                                    ),
                                    child: Text(
                                      slot,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : kDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            
                            Text('Catatan (Opsional)', style: AppText.label),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _catatanController,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan catatan tambahan...',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _selectedDate == null || _selectedTimeSlot == null || _loading
                                    ? null
                                    : () async {
                                        setState(() => _loading = true);
                                        final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                                        await widget.onDaftar(
                                          tarianId: widget.tarian.id,
                                          tanggal: dateStr,
                                          jam: _selectedTimeSlot,
                                          catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _loading = false;
                                            _expanded = false;
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusFull)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Kirim Booking', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ] else ...[
                            // ── Regular Member Class Schedules ──
                            Text('Pilih Jadwal Latihan Rutin', style: AppText.label),
                            const SizedBox(height: 6),
                            ...widget.jadwal.map((j) {
                              final isSelected = _selectedJadwal == j.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedJadwal = j.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? kPrimaryPale : Colors.white,
                                    borderRadius: BorderRadius.circular(kRadiusXs),
                                    border: Border.all(
                                      color: isSelected ? kPrimary : kBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                        color: isSelected ? kPrimary : kMuted,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              j.hari,
                                              style: TextStyle(
                                                color: isSelected ? kPrimary : kDark,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '⏰ ${j.jamMulai} – ${j.jamSelesai}  ·  📍 ${j.tempat}',
                                              style: AppText.bodyXs,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 12),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _selectedJadwal == null || _loading ? null : () async {
                                  setState(() => _loading = true);
                                  await widget.onDaftar(
                                    tarianId: widget.tarian.id,
                                    jadwalId: _selectedJadwal!,
                                  );
                                  if (mounted) setState(() { _loading = false; _expanded = false; });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusFull)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Daftar Kelas Ini', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
          ],
        ),
      ),
    ],
  ),
),
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
    final auth = context.watch<AuthProvider>();
    final isPengunjung = auth.user?.isPengunjung == true;

    if (daftar.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: kPrimaryPale, 
            borderRadius: BorderRadius.circular(kRadiusLg),
            boxShadow: [
              BoxShadow(color: kPrimary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(Icons.event_note_rounded, color: kPrimary, size: 32)),
        SizedBox(height: kSpace),
        Text(isPengunjung ? 'Belum ada booking sesi' : 'Belum ada kelas terdaftar', 
            style: AppText.displayXs.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Text(isPengunjung ? 'Pilih tarian dari tab pertama untuk membooking' : 'Pilih kelas tari dari tab "Pilih Kelas"',
            style: TextStyle(color: kMuted)),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(kSpace),
      itemCount: daftar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final d = daftar[i];
        
        // Parse dynamic ticket calendar blocks
        final isRoutine = !d.hariSingkat.contains('\n');
        final String topText;
        final String bottomText;
        if (isRoutine) {
          topText = d.hariSingkat; // e.g. "SEN", "MIN"
          bottomText = 'RUTIN';
        } else {
          final dateParts = d.hariSingkat.split('\n');
          topText = dateParts.first; // e.g. "18"
          bottomText = dateParts.length > 1 ? dateParts[1] : 'TGL';
        }

        return Container(
          padding: const EdgeInsets.all(kSpace),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadiusLg),
            border: Border.all(color: kBorder2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            // SLICK TICKET-STYLE DATE BADGE
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(kRadiusSm),
                boxShadow: [
                  BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(topText, 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: isRoutine ? 15 : 20, 
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  )),
                const SizedBox(height: 2),
                Text(bottomText, 
                  style: const TextStyle(
                    color: Colors.white70, 
                    fontSize: 8, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 1.0,
                  )),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(d.tarianNama, style: AppText.label, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                _buildStatusBadge(d.status),
              ]),
              const SizedBox(height: 4),
              Text(d.jamSelesai.isNotEmpty ? '⏰ ${d.jamMulai} – ${d.jamSelesai}' : '⏰ ${d.jamMulai} WIB',
                  style: AppText.bodyXs.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('📍 ${d.tempat}', style: AppText.bodyXs),
            ])),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onBatalkan(d.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(color: const Color(0xFFFECACA))),
                child: const Text('Batal',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w800))),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPending = status == 'nonaktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPending ? const Color(0xFFFFB74D) : const Color(0xFF81C784),
          width: 0.8,
        ),
      ),
      child: Text(
        isPending ? 'Pending' : 'Aktif',
        style: TextStyle(
          color: isPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}