// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/auto_slider.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SanggarProfile? _profil;
  List<Galeri>    _galeri  = [];
  List<Tarian>    _tarian  = [];
  List<Event>     _events  = [];
  bool            _loading = true;
  String?         _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getProfil(),
        ApiService.getGaleri(),
        ApiService.getTarian(),
        ApiService.getEvents(),
      ]);
      if (!mounted) return;
      final evData = results[3] as Map<String, dynamic>;
      setState(() {
        _profil  = results[0] as SanggarProfile;
        _galeri  = results[1] as List<Galeri>;
        _tarian  = (results[2] as List<Tarian>).take(6).toList();
        _events  = (evData['featured'] as List<Event>).take(3).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<SlideItem> get _slides {
    final heroGaleri = _galeri.where((g) => g.seksi == 'hero').toList();
    if (heroGaleri.isEmpty) {
      return [
        SlideItem(
          title:    _profil?.tagline ?? 'Melestarikan Budaya Melalui Seni',
          subtitle: _profil?.namaSanggar ?? 'Sanggar Mulya Bhakti',
          badge:    'SANGGAR SENI TRADISIONAL',
        ),
        SlideItem(
          title:    '${_profil?.jumlahPenghargaan ?? 49}+ Penghargaan',
          subtitle: 'Tingkat Nasional & Internasional',
          badge:    'PRESTASI KAMI',
        ),
        SlideItem(
          title:    'Lestarikan Budaya Bersama Kami',
          subtitle: 'Bergabung & mulai perjalanan seni Anda',
          badge:    'KOMUNITAS',
        ),
      ];
    }
    return heroGaleri.map((g) => SlideItem(
      imageUrl: g.url,
      title:    _profil?.tagline,
      badge:    'SANGGAR SENI TRADISIONAL',
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: _loading
          ? const AppLoading(message: 'Memuat data...')
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color:     kPrimary,
                  onRefresh: _load,
                  child: CustomScrollView(slivers: [

                    // ── SLIM HEADER ──
                    SliverToBoxAdapter(child: _buildHeader()),

                    // ── HERO SLIDER ──
                    SliverToBoxAdapter(
                      child: AutoSlider(
                        items:    _slides,
                        height:   320,
                        interval: const Duration(seconds: 5),
                      ),
                    ),

                    // ── STATS STRIP ──
                    SliverToBoxAdapter(child: _buildStats()),

                    // ── ABOUT SECTION ──
                    SliverToBoxAdapter(child: _buildAbout()),

                    // ── ARSIP TARIAN ──
                    SliverToBoxAdapter(
                      child: SectionTitle(
                        title:       'Tarian Khas Indramayu',
                        subtitle:    'ARSIP DIGITAL',
                        actionLabel: 'Lihat semua',
                        onAction:    () {},
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildTarianList()),

                    // ── EVENT UNGGULAN ──
                    if (_events.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: SectionTitle(
                          title:       'Event Unggulan',
                          subtitle:    'JEJAK PRESTASI',
                          actionLabel: 'Semua event',
                          onAction:    () {},
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildEventList()),
                    ],

                    // ── DOKUMENTASI SLIDER ──
                    SliverToBoxAdapter(child: _buildDokumentasiSlider()),

                    // ── CTA ──
                    SliverToBoxAdapter(child: _buildCta()),
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ]),
                ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: kBgCard,
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 10,
        left:   kSpace,
        right:  kSpace,
        bottom: 12,
      ),
      child: Row(children: [
        // Logo
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        kPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('SMB',
            style: TextStyle(color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_profil?.namaSanggar ?? 'Sanggar Mulya Bhakti',
            style: AppText.displayXs.copyWith(fontSize: 15)),
          Text('Indramayu, Jawa Barat',
            style: AppText.caption),
        ])),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: kDark, size: 22),
          onPressed: () {},
        ),
      ]),
    );
  }

  // ── STATS ──────────────────────────────────────────────────
  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(kSpace, 0, kSpace, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color:        kBgCard,
          borderRadius: BorderRadius.circular(kRadius),
          border:       Border.all(color: kBorder2),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          StatItem(
            number: '${_profil?.jumlahAnggota ?? 0}+',
            label:  'Anggota Aktif',
            icon:   Icons.people_rounded,
          ),
          const SizedBox(width: 10),
          StatItem(
            number: '${_profil?.jumlahPenghargaan ?? 0}+',
            label:  'Penghargaan',
            icon:   Icons.emoji_events_rounded,
          ),
          const SizedBox(width: 10),
          StatItem(
            number: '${_profil?.jumlahEvent ?? 0}+',
            label:  'Event Diikuti',
            icon:   Icons.event_rounded,
          ),
        ]),
      ),
    );
  }

  // ── ABOUT ──────────────────────────────────────────────────
  Widget _buildAbout() {
    if (_profil == null) return const SizedBox.shrink();
    final sejarah = _profil!.sejarah;
    return Container(
      margin: const EdgeInsets.fromLTRB(kSpace, kSpaceLg, kSpace, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppBadge('TENTANG KAMI'),
        const SizedBox(height: 10),
        Text(_profil!.namaSanggar, style: AppText.displayMd),
        if (_profil!.tahunBerdiri != null)
          Text('Berdiri sejak ${_profil!.tahunBerdiri}',
            style: AppText.caption.copyWith(color: kPrimary, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text(
          sejarah.length > 220 ? '${sejarah.substring(0, 220)}...' : sejarah,
          style: AppText.bodyMd.copyWith(color: kMuted, height: 1.7),
        ),
        const SizedBox(height: 12),
        _TextLink('Baca selengkapnya →', onTap: () {}),
      ]),
    );
  }

  // ── TARIAN LIST ────────────────────────────────────────────
  Widget _buildTarianList() {
    if (_tarian.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(horizontal: kSpace),
      child: Text('Belum ada data tarian.', style: TextStyle(color: kMuted)),
    );

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: kSpace),
        itemCount:        _tarian.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder:      (_, i)  => _TarianCard(tarian: _tarian[i]),
      ),
    );
  }

  // ── EVENT LIST ─────────────────────────────────────────────
  Widget _buildEventList() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: kSpace),
        itemCount:        _events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder:      (_, i)  => _EventCard(event: _events[i]),
      ),
    );
  }

  // ── DOKUMENTASI SLIDER ─────────────────────────────────────
  Widget _buildDokumentasiSlider() {
    final dok = _galeri.where((g) => g.seksi == 'dokumentasi').toList();
    if (dok.isEmpty) return const SizedBox.shrink();

    final slides = dok.map((g) => SlideItem(imageUrl: g.url)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(title: 'Dokumentasi Kegiatan', subtitle: 'GALERI'),
      AutoSlider(items: slides, height: 220, interval: const Duration(seconds: 3)),
      const SizedBox(height: kSpace),
    ]);
  }

  // ── CTA ────────────────────────────────────────────────────
  Widget _buildCta() {
    return Container(
      margin: const EdgeInsets.fromLTRB(kSpace, kSpaceLg, kSpace, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:        kPrimary,
        borderRadius: BorderRadius.circular(kRadiusXl),
        image: const DecorationImage(
          image:     AssetImage('assets/images/batik_pattern.png'),
          fit:       BoxFit.cover,
          opacity:   0.08,
        ),
      ),
      child: Column(children: [
        const Text('Bergabung dengan\nKomunitas Kami',
          style: TextStyle(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w900, height: 1.25,
            fontFamily: 'PlayfairDisplay',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Jadilah bagian dari gerakan pelestarian budaya Indramayu.',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen(showRegister: true))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Daftar Sekarang',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}

// ── TARIAN CARD ──────────────────────────────────────────────
class _TarianCard extends StatelessWidget {
  final Tarian tarian;
  const _TarianCard({required this.tarian});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 165,
        decoration: BoxDecoration(
          color:        kBgCard,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: tarian.unggulan ? kPrimary : kBorder2,
            width: tarian.unggulan ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color:  Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AppImage(
              url:          tarian.foto,
              height:       115,
              width:        165,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius - 1)),
              placeholder: Container(
                height: 115, color: kPrimaryPale,
                child: const Center(child: Icon(Icons.music_note_rounded,
                    color: kPrimary, size: 32))),
            ),
            if (tarian.unggulan)
              Positioned(top: 8, left: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: kGold, borderRadius: BorderRadius.circular(kRadiusFull)),
                child: const Text('★ Unggulan', style: TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              )),
            Positioned(
              top: 8, right: 8,
              child: CategoryChip(tarian.kategori, small: true)),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tarian.nama, style: AppText.label,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 10, color: kMuted),
                const SizedBox(width: 2),
                Expanded(child: Text(tarian.asal,
                  style: AppText.bodyXs, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── EVENT CARD ───────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color:        kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border:       Border.all(color: kBorder2),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Foto
        Stack(children: [
          AppImage(
            url:          event.foto,
            height:       130,
            width:        260,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius - 1)),
            placeholder: Container(
              height: 130, color: kPrimaryPale,
              child: const Center(
                child: Icon(Icons.event_rounded, color: kPrimary, size: 36))),
          ),
          Positioned(
            top: 10, right: 10,
            child: CategoryChip(event.kategori, small: true)),
        ]),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(event.tahun,
                style: AppText.caption.copyWith(color: kPrimary)),
              const Spacer(),
              Text(event.level, style: AppText.caption),
            ]),
            const SizedBox(height: 4),
            Text(event.nama, style: AppText.label,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 10, color: kMuted),
              const SizedBox(width: 2),
              Expanded(child: Text(event.lokasi,
                style: AppText.bodyXs, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (event.hasil != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(kRadiusFull),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Text(event.hasil!, style: const TextStyle(
                    color: Color(0xFFF57F17), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── TEXT LINK ────────────────────────────────────────────────
class _TextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TextLink(this.text, {required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(text, style: AppText.bodyMd.copyWith(
      color:       kPrimary,
      fontWeight:  FontWeight.w700,
    )),
  );
}