// lib/screens/penjadwalan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/jadwal_pendaftaran.dart';
import 'notification_screen.dart';

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

    return Scaffold(
      backgroundColor: kBgSoft,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: kBgCard,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
              child: Row(
                children: [
                  // Foto Profil
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kPrimaryPale,
                    backgroundImage: (auth.user?.foto != null && auth.user!.foto!.isNotEmpty)
                        ? NetworkImage(getImageUrl(auth.user!.foto!)) as ImageProvider
                        : null,
                    child: (auth.user?.foto == null || auth.user!.foto!.isEmpty)
                        ? Text(
                            auth.user?.initial ?? 'A',
                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 14),
                          )
                        : null,
                  ),
                  // Judul Tengah
                  Expanded(
                    child: Text(
                      'Sanggar Tari',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                  ),
                  // Ikon Notifikasi
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                    child: Icon(Icons.notifications_outlined, color: kPrimary, size: 26),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Container(
                margin: const EdgeInsets.fromLTRB(kSpaceMd, 0, kSpaceMd, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE5),
                  borderRadius: BorderRadius.circular(kRadiusFull),
                ),
                child: TabBar(
                  controller: _tab,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kRadiusFull),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  labelColor: kPrimary,
                  unselectedLabelColor: kMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    Tab(text: 'Pilih Kelas (${_tarian.length})'),
                    Tab(text: 'Terdaftar (${_daftar.length})'),
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
    String? tanggal,
    String? jam,
    String? catatan,
  }) async {
    try {
      await ApiService.daftarKelas(
        tarianId: tarianId,
        tanggalLatihan: tanggal!,
        jamLatihan: jam!,
        catatan: catatan,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Pendaftaran berhasil diajukan!'),
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

class _PilihKelasTab extends StatefulWidget {
  final List<Tarian> tarian;
  final List<JadwalLatihan> jadwal;
  final List<Pendaftaran> daftarSaya;

  final Future<void> Function({
    required int tarianId,
    String? tanggal,
    String? jam,
    String? catatan,
  }) onDaftar;

  final Tarian? initialTarian;

  const _PilihKelasTab({
    super.key,
    required this.tarian,
    required this.jadwal,
    required this.daftarSaya,
    required this.onDaftar,
    this.initialTarian,
  });

  @override
  State<_PilihKelasTab> createState() => _PilihKelasTabState();
}

class _PilihKelasTabState extends State<_PilihKelasTab> {
  bool _loadingJumat = false;
  bool _loadingMinggu = false;

  // ─────────────────────────────────────────────────────────
  // TANGGAL LATIHAN RUTIN
  // ─────────────────────────────────────────────────────────

  String _getNextFridayDate() {
    final now = DateTime.now();

    int daysToAdd =
        (DateTime.friday - now.weekday + 7) % 7;

    if (daysToAdd == 0) {
      daysToAdd = 7;
    }

    final nextFriday = now.add(
      Duration(days: daysToAdd),
    );

    return '${nextFriday.year}-'
        '${nextFriday.month.toString().padLeft(2, '0')}-'
        '${nextFriday.day.toString().padLeft(2, '0')}';
  }

  String _getNextSundayDate() {
    final now = DateTime.now();

    int daysToAdd =
        (DateTime.sunday - now.weekday + 7) % 7;

    if (daysToAdd == 0) {
      daysToAdd = 7;
    }

    final nextSunday = now.add(
      Duration(days: daysToAdd),
    );

    return '${nextSunday.year}-'
        '${nextSunday.month.toString().padLeft(2, '0')}-'
        '${nextSunday.day.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────
  // HEADER SECTION
  // ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: kDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: kBorder2,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // CARD PROGRAM LATIHAN RUTIN
  // ─────────────────────────────────────────────────────────

Widget _buildRutinCard({
  required String dayCode,
  required String title,
  required String timeStr,
  required String tarianStr,
  required String? foto,
  required bool isRegistered,
  required String buttonText,
  required bool isLoading,
  required VoidCallback onPressed,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(kRadiusLg),
      border: Border.all(
        color: isRegistered
            ? const Color(0xFF2E7D32)
            : kBorder2,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ─────────────────────────────
        // GAMBAR
        // ─────────────────────────────

        ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusSm),
          child: AppImage(
            url: foto,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            placeholder: Container(
              width: 90,
              height: 90,
              color: kPrimaryPale,
              child: const Icon(
                Icons.music_note_rounded,
                color: kPrimary,
                size: 28,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ─────────────────────────────
        // INFORMASI
        // ─────────────────────────────

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BADGE JADWAL / HARI
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryPale,
                  borderRadius: BorderRadius.circular(kRadiusFull),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 5),

              // NAMA TARIAN
              Text(
                tarianStr,
                style: TextStyle(
                  color: kDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'PlayfairDisplay',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 5),

              // LOKASI
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: kMuted,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Sanggar Mulya Bhakti',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              // WAKTU
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: kMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // STATUS
              if (isRegistered) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius:
                        BorderRadius.circular(kRadiusFull),
                  ),
                  child: const Text(
                    '✓ Terdaftar',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ─────────────────────────────
        // TOMBOL DAFTAR
        // ─────────────────────────────

        if (!isRegistered)
          GestureDetector(
            onTap: isLoading ? null : onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(kRadiusLg),
                border: Border.all(
                  color: kPrimary,
                  width: 1.5,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: kPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isPengunjung =
        auth.user?.isPengunjung == true;

    final sudahDaftarIds = isPengunjung
        ? <int>{}
        : widget.daftarSaya
            .map((d) => d.tarianId)
            .toSet();

    // Cari Tari Topeng Kelana
    final topengKelana = widget.tarian.firstWhere(
      (t) => t.nama
          .toLowerCase()
          .contains('topeng kelana'),
      orElse: () => widget.tarian.isNotEmpty
          ? widget.tarian.first
          : Tarian(
              id: 1,
              nama: 'Tari Topeng Kelana',
              kategori: 'Klasik',
              deskripsi: '',
              asal: 'Cirebon',
              foto: null,
              unggulan: false,
            ),
    );

    // Cek status pendaftaran Jumat
    final isRegisteredJumat =
        widget.daftarSaya.any(
      (d) =>
          d.jamMulai.contains('14:00') ||
          d.hari.toLowerCase().contains('jumat'),
    );

    // Cek status pendaftaran Minggu
    final isRegisteredMinggu =
        widget.daftarSaya.any(
      (d) =>
          d.jamMulai.contains('08:00') ||
          d.hari.toLowerCase().contains('minggu'),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        kSpaceMd,
        kSpace,
        kSpaceMd,
        kSpace,
      ),
      children: [
        // ─────────────────────────────────────────
        // PROGRAM LATIHAN RUTIN
        // ─────────────────────────────────────────
        if (!isPengunjung) ...[
          _buildSectionHeader(
            'Program Latihan Rutin',
          ),

          const SizedBox(height: 16),

          // JUMAT
        _buildRutinCard(
          dayCode: 'J',
          title: 'Jumat Siang',
          timeStr: '14:00 - 16:00 WIB',
          tarianStr: 'Tari Topeng Kelana',
          foto: topengKelana.foto,
          isRegistered: isRegisteredJumat,
          buttonText: 'Daftar',
          isLoading: _loadingJumat,
          onPressed: () async {
            setState(() => _loadingJumat = true);

            await widget.onDaftar(
              tarianId: topengKelana.id,
              tanggal: _getNextFridayDate(),
              jam: '14:00',
              catatan: 'Latihan Rutin Jumat',
            );

            if (mounted) {
              setState(() => _loadingJumat = false);
            }
          },
        ),

          const SizedBox(height: 14),

          // MINGGU
        _buildRutinCard(
          dayCode: 'M',
          title: 'Minggu Pagi',
          timeStr: '08:00 - 10:00 WIB',
          tarianStr: 'Tari Topeng Kelana dan Gamelan',
          foto: topengKelana.foto,
          isRegistered: isRegisteredMinggu,
          buttonText: 'Daftar',
          isLoading: _loadingMinggu,
          onPressed: () async {
            setState(() => _loadingMinggu = true);

            await widget.onDaftar(
              tarianId: topengKelana.id,
              tanggal: _getNextSundayDate(),
              jam: '08:00',
              catatan: 'Latihan Rutin Minggu',
            );

            if (mounted) {
              setState(() => _loadingMinggu = false);
            }
          },
        ),
          
          const SizedBox(height: 28),
        ],

        // ─────────────────────────────────────────
        // SESI PRIVATE TAMBAHAN
        // ─────────────────────────────────────────

        _buildSectionHeader(
          isPengunjung
              ? 'Pilih Tarian Private'
              : 'Sesi Private Tambahan',
        ),

        const SizedBox(height: 16),

        // List Tarian
        ...widget.tarian.map((t) {
          final sudah =
              sudahDaftarIds.contains(t.id);

          final isHilite =
              widget.initialTarian?.id == t.id;

          return _TarianKelasCard(
            tarian: t,
            jadwal: widget.jadwal,
            sudahDaftar: sudah,
            highlighted: isHilite,
            onDaftar: widget.onDaftar,
          );
        }),
      ],
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

    // Cari jadwal yang cocok untuk tarian ini
    final jadwalTarian = widget.jadwal.where((j) => j.aktif).toList();
    final jamInfo = jadwalTarian.isNotEmpty ? jadwalTarian.first.jamMulai : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(
          color: widget.sudahDaftar ? const Color(0xFF2E7D32) : kBorder2,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Baris Utama ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gambar persegi
                ClipRRect(
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  child: AppImage(
                    url: t.foto,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 90, height: 90,
                      color: kPrimaryPale,
                      child: Icon(Icons.music_note_rounded, color: kPrimary, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge kategori
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryPale,
                          borderRadius: BorderRadius.circular(kRadiusFull),
                        ),
                        child: Text(
                          t.kategori,
                          style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Nama tarian
                      Text(
                        t.nama,
                        style: TextStyle(
                          color: kDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'PlayfairDisplay',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Lokasi & jam
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: kMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              jamInfo.isNotEmpty
                                  ? 'Sanggar Mulya Bhakti • $jamInfo WIB'
                                  : 'Sanggar Mulya Bhakti',
                              style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.sudahDaftar) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(kRadiusFull),
                          ),
                          child: const Text('✓ Terdaftar',
                            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Daftar
                if (!widget.sudahDaftar)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _expanded ? kPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(kRadiusLg),
                        border: Border.all(color: kPrimary, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded ? 'Tutup' : (isPengunjung ? 'Private' : 'Daftar'),
                            style: TextStyle(
                              color: _expanded ? Colors.white : kPrimary,
                              fontSize: 12,
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
          ),

          // ── Form Pendaftaran (expanded) ──
          if (_expanded && !widget.sudahDaftar)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBgSoft,
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: kBorder2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPengunjung ? 'Tanggal Private' : 'Tanggal Latihan', style: AppText.label),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: kPrimary, onPrimary: Colors.white, onSurface: kDark),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(kRadiusXs), border: Border.all(color: kBorder),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: kPrimary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate == null ? 'Ketuk untuk pilih tanggal...' : _formatDate(_selectedDate!),
                          style: TextStyle(color: _selectedDate == null ? kMuted : kDark, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(isPengunjung ? 'Pilih Jam Private' : 'Pilih Jam Latihan', style: AppText.label),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00','20:00'].map((slot) {
                      final isSelected = _selectedTimeSlot == slot;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTimeSlot = slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(kRadiusXs),
                            border: Border.all(color: isSelected ? kPrimary : kBorder),
                          ),
                          child: Text(slot, style: TextStyle(color: isSelected ? Colors.white : kDark, fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('Catatan (Opsional)', style: AppText.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _catatanController,
                    decoration: const InputDecoration(hintText: 'Masukkan catatan tambahan...', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedDate == null || _selectedTimeSlot == null || _loading ? null : () async {
                        setState(() => _loading = true);
                        final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}';
                        await widget.onDaftar(tarianId: widget.tarian.id, tanggal: dateStr, jam: _selectedTimeSlot, catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim());
                        if (mounted) setState(() { _loading = false; _expanded = false; });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusFull)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isPengunjung ? 'Ajukan Private' : 'Daftar Kelas Ini', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
        Text(isPengunjung ? 'Belum ada sesi private' : 'Belum ada kelas terdaftar', 
             style: AppText.displayXs.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        Text(isPengunjung ? 'Pilih tarian dari tab pertama untuk mengajukan sesi private' : 'Pilih kelas tari dari tab "Pilih Kelas"',
            style: TextStyle(color: kMuted)),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(kSpaceMd, kSpace, kSpaceMd, kSpace),
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
          padding: const EdgeInsets.fromLTRB(kSpaceMd, kSpace, kSpaceMd, kSpace),
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
    final isPending = status == 'pending';
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