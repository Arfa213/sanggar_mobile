// lib/screens/archive_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});
  @override State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Tarian> _all = [], _filtered = [];
  String _filter = 'semua', _search = '';
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  static const _filters = ['semua','sakral','hiburan','penyambutan','ritual','perang'];
  static const _labels  = {
    'semua':'Semua','sakral':'Sakral','hiburan':'Hiburan',
    'penyambutan':'Penyambutan','ritual':'Ritual','perang':'Perang',
  };

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getTarian();
      if (!mounted) return;
      setState(() { _all = data; _loading = false; _apply(); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _apply() {
    setState(() {
      _filtered = _all.where((t) {
        final cat    = _filter == 'semua' || t.kategori == _filter;
        final search = _search.isEmpty ||
            t.nama.toLowerCase().contains(_search.toLowerCase());
        return cat && search;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned:     true,
            backgroundColor: kBgCard,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppBadge('WARISAN BUDAYA'),
                Text('Arsip Digital', style: AppText.displaySm),
              ]),
            ),
            toolbarHeight: 72,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Container(
                color: kBgCard,
                child: Column(children: [
                  const AppDivider(),
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSpace, 10, kSpace, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      style:      TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama tarian...',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: kMuted, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        filled:    true,
                        fillColor: kBgSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusFull),
                          borderSide:   BorderSide.none,
                        ),
                      ),
                      onChanged: (v) { _search = v; _apply(); },
                    ),
                  ),
                  // Filter
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:         const EdgeInsets.symmetric(horizontal: kSpace),
                      itemCount:       _filters.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f      = _filters[i];
                        final active = f == _filter;
                        return GestureDetector(
                          onTap: () { _filter = f; _apply(); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? kPrimary : kBgCard,
                              borderRadius: BorderRadius.circular(kRadiusFull),
                              border: Border.all(
                                color: active ? kPrimary : kBorder,
                              ),
                            ),
                            child: Text(_labels[f]!,
                              style: TextStyle(
                                color:      active ? Colors.white : kMuted,
                                fontSize:   12,
                                fontWeight: FontWeight.w700,
                              )),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                ]),
              ),
            ),
          ),
        ],
        body: _loading ? const AppLoading()
            : _error != null ? AppError(message: _error!, onRetry: _load)
            : _filtered.isEmpty
                ? Center(child: Text('Tarian tidak ditemukan.',
                    style: TextStyle(color: kMuted)))
                : RefreshIndicator(
                    color:     kPrimary,
                    onRefresh: _load,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(kSpace),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing:  12,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _TarianGridCard(
                        tarian: _filtered[i],
                        onTap:  () => _detail(_filtered[i]),
                      ),
                    ),
                  ),
      ),
    );
  }

  void _detail(Tarian t) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TarianDetailSheet(tarian: t),
  );
}

// ── GRID CARD ────────────────────────────────────────────────
class _TarianGridCard extends StatelessWidget {
  final Tarian     tarian;
  final VoidCallback onTap;
  const _TarianGridCard({required this.tarian, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(gIsDarkMode ? 0.3 : 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Gambar Full
              AppImage(
                url:   tarian.foto,
                fit:   BoxFit.cover,
                placeholder: Container(
                  color: kPrimaryPale,
                  child: Center(child: Icon(Icons.music_note_rounded, color: kPrimary, size: 32)),
                ),
              ),

              // 2. Gradient Gelap dari Bawah
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // 3. Kategori (Kanan Atas)
              Positioned(
                top: 8, right: 8,
                child: CategoryChip(tarian.kategori, small: true),
              ),

              // 4. Bintang Unggulan (Kiri Atas)
              if (tarian.unggulan)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kGold,
                      borderRadius: BorderRadius.circular(kRadiusFull),
                      boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text('Unggulan', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

              // 5. Teks Judul & Asal di Bawah
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tarian.nama,
                      style: AppText.displayXs.copyWith(color: Colors.white, fontSize: 15, height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tarian.asal,
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
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
        ),
      ),
    );
  }
}

// ── DETAIL SHEET ─────────────────────────────────────────────
class _TarianDetailSheet extends StatelessWidget {
  final Tarian tarian;
  const _TarianDetailSheet({required this.tarian});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize:     0.95,
      minChildSize:     0.45,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
        ),
        child: Column(children: [
          // Handle
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: kBorder, borderRadius: BorderRadius.circular(2)),
          )),
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Hero image
              Stack(children: [
                AppImage(
                  url:    tarian.foto,
                  height: 240,
                  width:  double.infinity,
                  placeholder: Container(
                    height: 200, color: kPrimaryPale,
                    child: Center(child: Icon(Icons.music_note_rounded,
                        color: kPrimary, size: 48))),
                ),
                // Gradient overlay on image
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.bottomCenter,
                        end:    Alignment.topCenter,
                        colors: [kBgCard, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ]),

              Padding(
                padding: const EdgeInsets.fromLTRB(kSpace, 4, kSpace, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CategoryChip(tarian.kategori),
                    if (tarian.unggulan) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(kRadiusFull),
                          border: Border.all(color: kGold.withOpacity(0.5)),
                        ),
                        child: Text('★ Unggulan', style: TextStyle(
                            color: kGold, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  SizedBox(height: 12),
                  Text(tarian.nama, style: AppText.displayLg),
                  SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 14, color: kMuted),
                    SizedBox(width: 4),
                    Text(tarian.asal, style: AppText.bodySm),
                  ]),
                  SizedBox(height: kSpace),

                  // Divider ornamental
                  Row(children: [
                    Container(width: 32, height: 2, color: kPrimary),
                    SizedBox(width: 6),
                    Container(width: 8, height: 2, color: kPrimaryLight),
                  ]),
                  SizedBox(height: kSpace),

                  Text(tarian.deskripsi,
                    style: AppText.bodyMd.copyWith(height: 1.75)),

                  // Info cards
                  SizedBox(height: kSpaceMd),
                  if (tarian.fungsi != null || tarian.kostum != null || tarian.durasi != null)
                    Container(
                      padding: const EdgeInsets.all(kSpace),
                      decoration: BoxDecoration(
                        color:        kBgSoft,
                        borderRadius: BorderRadius.circular(kRadius),
                        border:       Border.all(color: kBorder2),
                      ),
                      child: Column(children: [
                        if (tarian.fungsi != null)
                          _InfoTile('🎭', 'Fungsi Tarian', tarian.fungsi!),
                        if (tarian.kostum != null) ...[
                          const AppDivider(padding: EdgeInsets.zero),
                          _InfoTile('👘', 'Kostum', tarian.kostum!),
                        ],
                        if (tarian.durasi != null) ...[
                          const AppDivider(padding: EdgeInsets.zero),
                          _InfoTile('⏱', 'Durasi', tarian.durasi!),
                        ],
                      ]),
                    ),

                  if (tarian.videoUrl != null) ...[
                    SizedBox(height: kSpace),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon:  Icon(Icons.play_circle_rounded, size: 20),
                        label: Text('Tonton Video Tarian'),
                      ),
                    ),
                  ],
                  SizedBox(height: kSpaceXl),
                ]),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji, label, value;
  const _InfoTile(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Text(emoji, style: TextStyle(fontSize: 18)),
      SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption.copyWith(letterSpacing: 0.8)),
        SizedBox(height: 2),
        Text(value, style: AppText.label),
      ])),
    ]),
  );
}