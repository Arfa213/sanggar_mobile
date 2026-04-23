// lib/screens/event_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});
  @override State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Event>          _featured  = [];
  List<Event>          _selesai   = [];
  List<Event>          _mendatang = [];
  Map<String, dynamic> _stats     = {};
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getEvents();
      if (!mounted) return;
      setState(() {
        _featured  = data['featured']  as List<Event>;
        _selesai   = data['selesai']   as List<Event>;
        _mendatang = data['mendatang'] as List<Event>;
        _stats     = data['stats']     as Map<String, dynamic>;
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned:      true,
            backgroundColor: kBgCard,
            titleSpacing: 0,
            toolbarHeight: 72,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const AppBadge('JEJAK PRESTASI'),
                Text('Event & Pentas', style: AppText.displaySm),
              ]),
            ),
            bottom: TabBar(
              controller:           _tab,
              indicatorColor:       kPrimary,
              indicatorWeight:      2,
              labelColor:           kPrimary,
              unselectedLabelColor: kMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [Tab(text: 'Semua Event'), Tab(text: 'Akan Datang')],
            ),
          ),
        ],
        body: _loading ? const AppLoading()
            : _error != null ? AppError(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color:     kPrimary,
                onRefresh: _load,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _AllTab(
                      featured:  _featured,
                      selesai:   _selesai,
                      stats:     _stats,
                    ),
                    _MendatangTab(events: _mendatang),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── ALL TAB ──────────────────────────────────────────────────
class _AllTab extends StatelessWidget {
  final List<Event>          featured;
  final List<Event>          selesai;
  final Map<String, dynamic> stats;
  const _AllTab({required this.featured, required this.selesai, required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(kSpace),
      children: [
        // Stats
        _StatsRow(stats: stats),
        const SizedBox(height: kSpaceLg),

        // Unggulan
        if (featured.isNotEmpty) ...[
          Row(children: [
            const AppBadge('HIGHLIGHT'),
            const SizedBox(width: 10),
            Text('Event Unggulan', style: AppText.displayXs),
          ]),
          const SizedBox(height: kSpace),
          ...featured.map((e) => _FeaturedCard(event: e)),
          const SizedBox(height: kSpaceLg),
        ],

        // Timeline
        Row(children: [
          const AppBadge('REKAM JEJAK'),
          const SizedBox(width: 10),
          Text('Semua Event', style: AppText.displayXs),
        ]),
        const SizedBox(height: kSpace),
        if (selesai.isEmpty)
          const Text('Belum ada data event.', style: TextStyle(color: kMuted))
        else
          ...selesai.map((e) => _TimelineTile(event: e)),
      ],
    );
  }
}

// ── MENDATANG TAB ────────────────────────────────────────────
class _MendatangTab extends StatelessWidget {
  final List<Event> events;
  const _MendatangTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: kPrimaryPale, borderRadius: BorderRadius.circular(kRadius)),
          child: const Icon(Icons.event_available_rounded, color: kPrimary, size: 32),
        ),
        const SizedBox(height: kSpace),
        Text('Belum ada event mendatang', style: AppText.displayXs.copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Pantau terus untuk info terbaru!',
            style: TextStyle(color: kMuted)),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.all(kSpace),
      children: events.map((e) => _MendatangCard(event: e)).toList(),
    );
  }
}

// ── STATS ROW ────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpace),
      decoration: BoxDecoration(
        color:        kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border:       Border.all(color: kBorder2),
      ),
      child: Row(children: [
        StatItem(number: '${stats['total'] ?? 0}',          label: 'Total'),
        const SizedBox(width: 8),
        StatItem(number: '${stats['internasional'] ?? 0}',  label: 'Internasional'),
        const SizedBox(width: 8),
        StatItem(number: '${stats['penghargaan'] ?? 0}',    label: 'Penghargaan'),
      ]),
    );
  }
}

// ── FEATURED CARD ────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Event event;
  const _FeaturedCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpace),
      decoration: BoxDecoration(
        color:        kBgCard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border:       Border.all(color: kBorder2),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset:     const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Foto
        Stack(children: [
          AppImage(
            url:    event.foto,
            height: 180,
            width:  double.infinity,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(kRadiusLg - 1)),
            placeholder: Container(
              height: 180, color: kPrimaryPale,
              child: const Center(
                child: Icon(Icons.event_rounded, color: kPrimary, size: 44))),
          ),
          Positioned(top: 12, right: 12,
            child: CategoryChip(event.kategori)),
          // Year ribbon
          Positioned(bottom: 0, left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.only(
                  topRight:     Radius.circular(kRadius),
                  bottomRight:  Radius.circular(0),
                ),
              ),
              child: Text(event.tahun,
                style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
            )),
        ]),

        // Info
        Padding(
          padding: const EdgeInsets.all(kSpace),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(event.level, style: AppText.caption.copyWith(
                  color: kPrimary, letterSpacing: 1)),
              const Spacer(),
              if (event.jumlahPenonton != null)
                Row(children: [
                  const Icon(Icons.people_rounded, size: 12, color: kMuted),
                  const SizedBox(width: 3),
                  Text('${event.jumlahPenonton}+',
                      style: AppText.caption),
                ]),
            ]),
            const SizedBox(height: 6),
            Text(event.nama, style: AppText.displayXs),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 13, color: kMuted),
              const SizedBox(width: 3),
              Expanded(child: Text(event.lokasi,
                style: AppText.bodySm,
                overflow: TextOverflow.ellipsis)),
            ]),
            if (event.hasil != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border:       Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Text(event.hasil!,
                  style: const TextStyle(
                    color: Color(0xFFE65100), fontSize: 13,
                    fontWeight: FontWeight.w800)),
              ),
            ],
            if (event.penghargaan.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: event.penghargaan
                .take(3)
                .map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        kPrimaryPale,
                    borderRadius: BorderRadius.circular(kRadiusFull),
                    border:       Border.all(color: kPrimary.withOpacity(0.2)),
                  ),
                  child: Text(p, style: AppText.bodyXs.copyWith(
                      color: kPrimary, fontWeight: FontWeight.w700)),
                )).toList()),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── TIMELINE TILE ────────────────────────────────────────────
class _TimelineTile extends StatelessWidget {
  final Event event;
  const _TimelineTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tanggal kolom
        SizedBox(
          width: 52,
          child: Column(children: [
            Container(
              width: 52, height: 56,
              decoration: BoxDecoration(
                color:        kPrimary,
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(event.tgl, style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(event.bulanSingkat, style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
            ),
            // Vertical line
            Container(width: 1.5, height: 24, color: kBorder2),
          ]),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        kBgCard,
              borderRadius: BorderRadius.circular(kRadius),
              border:       Border.all(color: kBorder2),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CategoryChip(event.kategori, small: true),
                const Spacer(),
                Text(event.tahun, style: AppText.caption),
              ]),
              const SizedBox(height: 6),
              Text(event.nama, style: AppText.label,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 11, color: kMuted),
                const SizedBox(width: 2),
                Expanded(child: Text(event.lokasi,
                  style: AppText.bodyXs, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              if (event.hasil != null) ...[
                const SizedBox(height: 6),
                Text(event.hasil!,
                  style: AppText.bodySm.copyWith(
                    color: kPrimary, fontWeight: FontWeight.w800)),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ── MENDATANG CARD ───────────────────────────────────────────
class _MendatangCard extends StatelessWidget {
  final Event event;
  const _MendatangCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(kSpace),
      decoration: BoxDecoration(
        color:        kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder2),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryDark],
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(event.tgl, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(event.bulanSingkat, style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 10,
                fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.nama, style: AppText.label,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 11, color: kMuted),
            const SizedBox(width: 2),
            Expanded(child: Text(event.lokasi,
              style: AppText.bodyXs,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          CategoryChip(event.kategori, small: true),
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(kRadiusFull),
          ),
          child: const Text('Upcoming',
            style: TextStyle(color: Color(0xFF2E7D32),
                fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ]),
    );
  }
}