// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/auto_slider.dart';
import 'main_nav.dart';
import 'attendance/scan_screen.dart';
import 'chatbot_screen.dart';
import 'penjadwalan_screen.dart';
import '../services/notification_service.dart';
import 'notification_screen.dart';

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
        ]);
        if (!mounted) return;
        final ev = results[4] as Map<String, dynamic>;
        setState(() {
          _profil = results[0] as SanggarProfile;
          _jadwalAktif = results[1] as List<PendaftaranMember>;
          _kehadiran = (results[2] as List<Kehadiran>).take(5).toList();
          _statistik = results[3] as StatistikKehadiran;
          _events = ((ev['mendatang'] as List<Event>?) ?? []).take(3).toList();
          _loading = false;
        });

        // Trigger pengingat latihan real-time otomatis (24 jam & 1 jam)
        if (mounted) {
          context.read<NotificationService>().generateRealtimeReminders(
            user: auth.user!,
            pendaftaranList: _jadwalAktif,
          );
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

  Widget _buildMemberDashboard(AuthProvider auth) {
    final user = auth.user!;
    return Scaffold(
      backgroundColor: kBgSoft,
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildDashHeader(user)),
          SliverToBoxAdapter(child: _buildBentoQuickActions()),
          SliverToBoxAdapter(child: _buildScanButton()),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildJadwalSection()),
          SliverToBoxAdapter(child: _buildKehadiranSection()),
          SliverToBoxAdapter(child: _buildEventSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: kPrimary,
        child: Icon(Icons.forum_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBentoQuickActions() {
    return FadeTransition(
      opacity: _stagger(1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(
          children: [
            // Action 1: Booking Kelas / Penjadwalan
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PenjadwalanScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryPale,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: kPrimary,
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Booking Kelas',
                        style: TextStyle(
                          color: kText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Daftar / atur sesi latihan',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Action 2: Tanya AI Asisten
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tanya AI Asisten',
                        style: TextStyle(
                          color: kText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chatbot info sanggar',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 11,
                        ),
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

  Widget _buildDashHeader(UserModel user) {
    return FadeTransition(
      opacity: _stagger(0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [kPrimaryDark, kPrimary],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Selamat datang,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  Text(user.firstName, style: TextStyle(color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.w900, fontFamily: 'PlayfairDisplay')),
                ])),
                
                // Bel Notifikasi dengan Badge Unread
                Consumer<NotificationService>(
                  builder: (context, ns, child) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_active_outlined, color: Colors.white, size: 26),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          ),
                        ),
                        if (ns.unreadCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Center(
                                child: Text(
                                  '${ns.unreadCount}',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(width: 8),

                GestureDetector(
                  onTap: () => MainNav.of(context)?.setIndex = 3, // Ke Halaman Profil
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      image: (user.foto != null && user.foto!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(getImageUrl(user.foto!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (user.foto == null || user.foto!.isEmpty)
                        ? Center(child: Text(user.initial, style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)))
                        : null,
                  ),
                ),
              ]),
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(kRadiusFull),
                ),
                child: Text(
                  user.isAdmin ? '👑 Administrator' : (user.isPengunjung ? '🎭 Anggota Sementara' : '🎭 Anggota Tetap'),
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = _statistik;
    final items = [
      ('${_jadwalAktif.length}', 'Kelas Aktif', Icons.school_rounded, kPrimary),
      ('${s?.hadir ?? 0}', 'Hadir Bulan Ini', Icons.check_circle_outline_rounded, const Color(0xFF2E7D32)),
      ('${s?.persenHadir ?? 0}%', 'Tingkat Hadir', Icons.bar_chart_rounded, const Color(0xFF1565C0)),
    ];
    return FadeTransition(
      opacity: _stagger(3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: items.asMap().entries.map((e) {
          final idx = e.key; final item = e.value;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: idx == 0 ? 0 : 6, right: idx == 2 ? 0 : 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: kBorder2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(item.$3, color: item.$4, size: 18),
                SizedBox(height: 8),
                Text(item.$1, style: TextStyle(color: item.$4, fontSize: 20,
                    fontWeight: FontWeight.w900, fontFamily: 'PlayfairDisplay')),
                Text(item.$2, style: AppText.bodyXs, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ));
        }).toList()),
      ),
    );
  }

  Widget _buildScanButton() {
    return FadeTransition(
      opacity: _stagger(2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: GestureDetector(
          onTap: () async {
            final ok = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => const ScanScreen()));
            if (ok == true && mounted) { _load(); }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(kRadiusLg),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
              ),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Scan Kehadiran', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Arahkan kamera ke QR Code kelas', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalSection() {
    return FadeTransition(
      opacity: _stagger(4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            AppBadge('KELAS SAYA'),
            GestureDetector(
              //  UBAH JUGA TOMBOL KELOLA AGAR KE PENJADWALAN
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PenjadwalanScreen()),
                );
              },
              child: Text('Kelola', style: AppText.bodySm.copyWith(color: kPrimary, fontWeight: FontWeight.w700)),
            ),
          ]),
          SizedBox(height: 10),
          if (_jadwalAktif.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
              child: Column(children: [
                Icon(Icons.school_outlined, color: kMuted2, size: 32),
                SizedBox(height: 8),
                Text('Belum ada kelas aktif', style: AppText.label.copyWith(color: kMuted)),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PenjadwalanScreen()),
                    );
                  },
                  child: Text('Daftar kelas →', style: AppText.bodySm.copyWith(color: kPrimary, fontWeight: FontWeight.w700)),
                ),
              ]),
            )
          else
            ..._jadwalAktif.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(p.hariSingkat, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    Text(p.jadwal.jamMulai, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w700)),
                  ]),
                ),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.tarianNama, style: AppText.label),
                  SizedBox(height: 3),
                  Text('📍 ${p.jadwal.tempat}   ⏰ ${p.jadwal.jamMulai}–${p.jadwal.jamSelesai}',
                      style: AppText.bodyXs),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(kRadiusFull)),
                  child: Text('Aktif', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ]),
            )),
        ]),
      ),
    );
  }

  Widget _buildKehadiranSection() {
    if (_kehadiran.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _stagger(5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            AppBadge('KEHADIRAN TERAKHIR'),
            Text('Lihat semua', style: AppText.bodySm.copyWith(color: kPrimary, fontWeight: FontWeight.w700)),
          ]),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
            child: Column(children: _kehadiran.asMap().entries.map((e) {
              final k = e.value;
              final colors = {'hadir': [const Color(0xFFE8F5E9), const Color(0xFF2E7D32)],
                'izin': [const Color(0xFFFFF3E0), const Color(0xFFE65100)],
                'alpa': [const Color(0xFFFEF2F2), const Color(0xFFDC2626)]};
              final c = colors[k.status] ?? [kBorder2, kMuted];
              final icons = {'hadir': '✓', 'izin': '~', 'alpa': '✗'};
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(border: e.key < _kehadiran.length - 1
                    ? Border(bottom: BorderSide(color: Color(0xFFF5F5F5))) : null),
                child: Row(children: [
                  Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(icons[k.status] ?? '?',
                        style: TextStyle(color: c[1], fontWeight: FontWeight.w900)))),
                  SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k.tarianNama, style: AppText.label.copyWith(fontWeight: FontWeight.w600)),
                    Text(k.tanggalFormatted, style: AppText.bodyXs),
                  ])),
                  Text(k.status[0].toUpperCase() + k.status.substring(1),
                      style: TextStyle(color: c[1], fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              );
            }).toList()),
          ),
        ]),
      ),
    );
  }

  Widget _buildEventSection() {
    if (_events.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _stagger(6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppBadge('EVENT MENDATANG'),
          SizedBox(height: 10),
          ..._events.map((ev) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
            child: Row(children: [
              Container(
                width: 46, height: 52,
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(ev.tgl, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(ev.bulanSingkat, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ev.nama, style: AppText.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3),
                Text('📍 ${ev.lokasi}', style: AppText.bodyXs, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          )),
        ]),
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
          SliverToBoxAdapter(child: SectionTitle(title: 'Tarian Khas Indramayu', subtitle: 'ARSIP DIGITAL',
              actionLabel: 'Lihat semua', onAction: () => MainNav.of(context)?.setIndex = 1)),
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