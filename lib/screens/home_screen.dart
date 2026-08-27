// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/auto_slider.dart';
import 'main_nav.dart';
import 'attendance/scan_screen.dart';
import 'chatbot_screen.dart';
import '../services/notification_service.dart';
import 'notification_screen.dart';
import 'rapor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  SanggarProfile? _profil;
  List<Galeri> _galeri = [];
  List<Tarian> _tarian = [];
  List<Event> _events = [];
  List<PendaftaranMember> _jadwalAktif = [];
  List<Kehadiran> _kehadiran = [];
  List<Map<String, dynamic>> _pengumuman = [];
  StatistikKehadiran? _statistik;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _load();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        final results = await Future.wait([
          ApiService.getProfil(),
          ApiService.getPendaftaranSaya(),
          ApiService.getKehadiranSaya(),
          ApiService.getStatistikKehadiran(),
          ApiService.getEvents(),
          ApiService.getPengumuman(),
        ]);
        if (!mounted) return;
        final ev = results[4] as Map<String, dynamic>;
        setState(() {
          _profil = results[0] as SanggarProfile;
          _jadwalAktif = results[1] as List<PendaftaranMember>;
          _kehadiran = (results[2] as List<Kehadiran>).take(5).toList();
          _statistik = results[3] as StatistikKehadiran;
          _events = ((ev['mendatang'] as List<Event>?) ?? []).take(3).toList();
          _pengumuman = results[5] as List<Map<String, dynamic>>;
          _loading = false;
        });

        // Trigger pengingat latihan real-time otomatis (24 jam & 1 jam)
        if (mounted) {
          final ns = context.read<NotificationService>();
          ns.generateRealtimeReminders(
            user: auth.user!,
            pendaftaranList: _jadwalAktif,
          );
          // Deteksi alpa otomatis: jika jadwal sudah lewat & belum scan → kirim alpa
          ns.checkAndMarkAbsent(pendaftaranList: _jadwalAktif);
        }
      } else {
        final results = await Future.wait([
          ApiService.getProfil(), ApiService.getGaleri(),
          ApiService.getTarian(), ApiService.getEvents(),
        ]);
        if (!mounted) return;
        final ev = results[3] as Map<String, dynamic>;
        setState(() {
          _profil = results[0] as SanggarProfile;
          _galeri = results[1] as List<Galeri>;
          _tarian = (results[2] as List<Tarian>).take(6).toList();
          _events = ((ev['featured'] as List<Event>?) ?? []).take(3).toList();
          _loading = false;
        });
      }
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Animation<double> _stagger(int i) => CurvedAnimation(
    parent: _animCtrl,
    curve: Interval(i * 0.1, (i * 0.1 + 0.5).clamp(0, 1), curve: Curves.easeOut),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_loading) return const Scaffold(body: AppLoading(message: 'Memuat...'));
    if (_error != null) return Scaffold(body: AppError(message: _error!, onRetry: _load));
    return auth.isLoggedIn ? _buildMemberDashboard(auth) : _buildPublicHome();
  }

  List<BoxShadow> get _softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  Widget _buildMemberDashboard(AuthProvider auth) {
    final user = auth.user!;
    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: _buildDashHeader(user),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _buildModernQuickGrid(),
            if (_jadwalAktif.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildUpcomingClassWidget(),
            ],
            if (_pengumuman.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildAnnouncementCarousel(),
            ],
            const SizedBox(height: 32),
            _buildStatsRow(),
            if (_kehadiran.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildKehadiranSection(),
            ],
            if (_events.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildEventSection(),
            ],
            if (user.isPengunjung) ...[
              const SizedBox(height: 32),
              _buildUpgradeBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: kDark,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.33,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action,
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return FadeTransition(
      opacity: _stagger(7),
      child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kDark2,
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: kGold, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                'Suka latihan di sini?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'PlayfairDisplay',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jadwal rutin, antrean private lebih cepat, dan prioritas aula sebagai Anggota Tetap.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(kRadiusSm),
                child: InkWell(
                  onTap: () {
                    // In a real app, this would open URL using url_launcher:
                    // launchUrl(Uri.parse('https://wa.me/6281234567890?text=Halo...'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Akan membuka WhatsApp Admin...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Hubungi Admin',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildAnnouncementCarousel() {
    if (_pengumuman.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _stagger(1),
      child: Column(
        children: _pengumuman.asMap().entries.map((entry) {
          final item = entry.value;
          final isEvent = item['tipe'] == 'event';
          final accent = isEvent ? kPrimary : const Color(0xFFBA1A1A);
          final date = item['created_at'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['created_at'] as String).toLocal())
              : '';
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < _pengumuman.length - 1 ? 12 : 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _softShadow,
                border: Border(left: BorderSide(color: accent, width: 4)),
              ),
              clipBehavior: Clip.none,
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    top: -16,
                    child: Icon(Icons.campaign_rounded, size: 100, color: accent.withOpacity(0.08)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isEvent ? Icons.event_rounded : Icons.warning_rounded, color: accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${isEvent ? 'Event' : 'Pengumuman'}${date.isEmpty ? '' : ' • $date'}',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.02,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['judul'] ?? '-',
                        style: TextStyle(
                          color: kDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['konten'] ?? '-',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingClassWidget() {
    if (_jadwalAktif.isEmpty) return const SizedBox.shrink();
    // Cari kelas terdekat (untuk demonstrasi, kita ambil index pertama saja)
    final p = _jadwalAktif.first;
    return FadeTransition(
      opacity: _stagger(2),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _softShadow,
          border: Border(left: BorderSide(color: kPrimary, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latihan terdekat',
              style: TextStyle(
                color: kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p.tarianNama,
              style: TextStyle(
                color: kDark,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place_outlined, color: kMuted, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    p.jadwal.tempat,
                    style: TextStyle(color: kMuted, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.schedule_outlined, color: kMuted, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${p.jadwal.hari}, ${p.jadwal.jamMulai}',
                  style: TextStyle(color: kMuted, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hadir 10 menit sebelum kelas dimulai',
                    style: TextStyle(color: kMuted2, fontSize: 12, height: 1.3),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  child: InkWell(
                    onTap: () async {
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                      if (ok == true && mounted) { _load(); }
                    },
                    borderRadius: BorderRadius.circular(kRadiusSm),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'Scan Absen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickGrid() {
    final user = context.read<AuthProvider>().user;
    final isAnggotaTetap = user != null && user.tipeAnggota == 'anggota_tetap';
    
    final items = [
      (
        'Scan QR',
        'Absensi kehadiran kelas',
        Icons.qr_code_scanner_rounded,
        kPrimary,
        kPrimaryPale,
        () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
          if (ok == true && mounted) { _load(); }
        }
      ),
      if (isAnggotaTetap)
        (
          'Rapor Saya',
          'Nilai ujian pagelaran',
          Icons.school_rounded,
          kPrimaryDark,
          kPrimaryPale2,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RaporScreen()),
          )
        ),
      (
        'Kelas Tari',
        'Daftar sesi & kelas latihan',
        Icons.sports_martial_arts_rounded,
        kPrimary,
        kPrimaryPale,
        () => MainNav.of(context)?.setIndex = 1 // Pindah ke tab Jadwal
      ),
      (
        'Tanya AI',
        'Asisten info budaya',
        Icons.smart_toy_rounded,
        kPrimaryDark,
        kPrimaryPale2,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        )
      ),
      if (!isAnggotaTetap)
        (
          'Materi Tari',
          'Video & materi belajar',
          Icons.auto_stories_rounded,
          kPrimary,
          kPrimaryPale,
          () => MainNav.of(context)?.setIndex = 2 // Pindah ke tab Materi
        ),
    ];

    return FadeTransition(
      opacity: _stagger(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Akses Cepat'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 132,
            ),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final item = items[idx];
              return Material(
                color: kBgCard,
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: item.$6 as VoidCallback,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: kPrimary.withOpacity(0.08),
                  highlightColor: kPrimary.withOpacity(0.04),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: kBgCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _softShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.$5,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.$3, color: item.$4, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$1,
                          style: TextStyle(
                            color: kDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDashHeader(UserModel user) {
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 76),
      child: Container(
        decoration: BoxDecoration(
          color: kBgSoft,
          boxShadow: _softShadow,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => MainNav.of(context)?.setIndex = 3,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryPale,
                      border: Border.all(color: kPrimary, width: 2),
                      image: (user.foto != null && user.foto!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(getImageUrl(user.foto!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (user.foto == null || user.foto!.isEmpty)
                        ? Center(
                            child: Text(
                              user.initial,
                              style: TextStyle(
                                color: kPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Halo, ${user.firstName}',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryPale2,
                              borderRadius: BorderRadius.circular(kRadiusFull),
                            ),
                            child: Text(
                              user.isAdmin
                                  ? 'Administrator'
                                  : (user.isPengunjung ? 'Anggota Sementara' : 'Anggota Tetap'),
                              style: TextStyle(
                                color: kPrimaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (user.isPengunjung && user.tglKadaluarsa != null)
                            Builder(
                              builder: (ctx) {
                                final tgl = DateTime.tryParse(user.tglKadaluarsa!);
                                if (tgl == null) return const SizedBox.shrink();
                                final sisaHari = tgl.difference(DateTime.now()).inDays;
                                final isExpired = sisaHari < 0;
                                final color = isExpired
                                    ? const Color(0xFFBA1A1A)
                                    : (sisaHari <= 2 ? Colors.orangeAccent : const Color(0xFF2E7D32));
                                final text = isExpired ? 'Hangus' : 'Sisa $sisaHari hari';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(kRadiusFull),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<NotificationService>(
                  builder: (context, ns, child) {
                    return Stack(
                      children: [
                        Material(
                          color: kBorder,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationScreen()),
                            ),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.notifications_outlined, color: kMuted, size: 22),
                            ),
                          ),
                        ),
                        if (ns.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA1A1A),
                                shape: BoxShape.circle,
                                border: Border.all(color: kBgSoft, width: 2),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = _statistik;
    final items = [
      ('${_jadwalAktif.length}', 'Kelas aktif', Icons.event_available_rounded, kPrimary),
      ('${s?.hadir ?? 0}', 'Hadir', Icons.schedule_rounded, kPrimaryDark),
      ('${s?.persenHadir ?? 0}%', 'Kehadiran', Icons.workspace_premium_rounded, kPrimary),
    ];
    return FadeTransition(
      opacity: _stagger(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Statistik Anda'),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.$4.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$3, color: item.$4, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color: kDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: item.$4,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildKehadiranSection() {
    if (_kehadiran.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _stagger(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Kehadiran terakhir'),
            Container(
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: kBorder2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: _kehadiran.asMap().entries.map((e) {
                  final k = e.value;
                  final colors = {
                    'hadir': [const Color(0xFFE8F5E9), const Color(0xFF2E7D32)],
                    'izin': [const Color(0xFFFFF3E0), const Color(0xFFE65100)],
                    'alpa': [const Color(0xFFFEF2F2), const Color(0xFFDC2626)],
                  };
                  final c = colors[k.status] ?? [kBorder2, kMuted];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      border: e.key < _kehadiran.length - 1
                          ? Border(bottom: BorderSide(color: kBorder2))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: c[1], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                k.tarianNama,
                                style: AppText.label.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(k.tanggalFormatted, style: AppText.bodyXs),
                            ],
                          ),
                        ),
                        Text(
                          k.status[0].toUpperCase() + k.status.substring(1),
                          style: TextStyle(color: c[1], fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildEventSection() {
    if (_events.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _stagger(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Event mendatang'),
            ..._events.map((ev) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: kBorder2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 54,
                    decoration: BoxDecoration(
                      color: kPrimaryPale,
                      borderRadius: BorderRadius.circular(kRadiusSm),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ev.tgl,
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          ev.bulanSingkat.toUpperCase(),
                          style: TextStyle(
                            color: kPrimary.withOpacity(0.75),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev.nama,
                          style: AppText.label.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 13, color: kMuted2),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                ev.lokasi,
                                style: AppText.bodyXs,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      );
  }

  Widget _buildPublicHome() {
    final heroGaleri = _galeri.where((g) => g.seksi == 'hero').toList();
    final slides = heroGaleri.isNotEmpty
        ? heroGaleri.map((g) => SlideItem(imageUrl: g.url, title: _profil?.tagline, badge: 'SANGGAR SENI TRADISIONAL')).toList()
        : [SlideItem(title: _profil?.tagline ?? 'Melestarikan Budaya Melalui Seni', badge: 'SANGGAR SENI TRADISIONAL')];

    return Scaffold(
      backgroundColor: kBgSoft,
      body: RefreshIndicator(color: kPrimary, onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildPublicHeader()),
          SliverToBoxAdapter(child: AutoSlider(items: slides, height: 300, interval: const Duration(seconds: 5))),
          if (_profil != null) SliverToBoxAdapter(child: _buildPublicStats()),
          SliverToBoxAdapter(child: SectionTitle(title: 'Tarian Khas Indramayu', subtitle: 'MATERI TARI',
              actionLabel: 'Lihat semua', onAction: () => MainNav.of(context)?.setIndex = 2)),
          SliverToBoxAdapter(child: _buildPublicTarian()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Widget _buildPublicHeader() {
    return Container(
      color: kBgCard,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: kSpace, right: kSpace, bottom: 12),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text('SMB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)))),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_profil?.namaSanggar ?? 'Sanggar Mulya Bhakti', style: AppText.displayXs.copyWith(fontSize: 15)),
          Text('Indramayu, Jawa Barat', style: AppText.caption),
        ])),
      ]),
    );
  }

  Widget _buildPublicStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(kSpace, 0, kSpace, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Row(children: [
        StatItem(number: '${_profil!.jumlahAnggota}+', label: 'Anggota Aktif', icon: Icons.people_rounded),
        SizedBox(width: 10),
        StatItem(number: '${_profil!.jumlahPenghargaan}+', label: 'Penghargaan', icon: Icons.emoji_events_rounded),
        SizedBox(width: 10),
        StatItem(number: '${_profil!.jumlahEvent}+', label: 'Event Diikuti', icon: Icons.event_rounded),
      ]),
    );
  }

  Widget _buildPublicTarian() {
    if (_tarian.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kSpace),
        itemCount: _tarian.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (_, i) {
          final t = _tarian[i];
          return Container(
            width: 155,
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: t.unggulan ? kPrimary : kBorder2, width: t.unggulan ? 1.5 : 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppImage(url: t.foto, height: 110, width: 155,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius - 1)),
                  placeholder: Container(height: 110, color: kPrimaryPale,
                      child: Center(child: Icon(Icons.music_note_rounded, color: kPrimary, size: 28)))),
              Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.nama, style: AppText.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3),
                Text(t.asal, style: AppText.bodyXs, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          );
        },
      ),
    );
  }
}