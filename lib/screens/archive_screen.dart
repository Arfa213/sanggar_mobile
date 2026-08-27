// lib/screens/archive_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'main_nav.dart';

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

  String _kategoriLabel(String k) =>
      _labels[k] ?? (k.isEmpty ? '-' : '${k[0].toUpperCase()}${k.substring(1)}');

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 64),
        child: Container(
          decoration: BoxDecoration(
            color: kBgSoft,
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sanggar Tari',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.33,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => MainNav.of(context)?.setIndex = 3,
                    child: Builder(
                      builder: (_) {
                        final foto = user?.foto;
                        final hasFoto = foto != null && foto.isNotEmpty;
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryPale,
                            border: Border.all(color: kBorder, width: 2),
                            image: hasFoto
                                ? DecorationImage(image: NetworkImage(getImageUrl(foto)), fit: BoxFit.cover)
                                : null,
                          ),
                          child: hasFoto
                              ? null
                              : Center(
                                  child: Text(
                                    user?.initial ?? 'U',
                                    style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materi Tari',
                      style: TextStyle(
                        color: kDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Koleksi materi tari tradisional Nusantara untuk pelestarian budaya.',
                      style: TextStyle(color: kMuted, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchCtrl,
                      style: TextStyle(fontSize: 14, color: kDark),
                      decoration: InputDecoration(
                        hintText: 'Cari nama tarian...',
                        hintStyle: TextStyle(color: kMuted),
                        prefixIcon: Icon(Icons.search_rounded, color: kMuted, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        filled: true,
                        fillColor: kBgCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kBorder2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kBorder2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary, width: 1.5),
                        ),
                      ),
                      onChanged: (v) { _search = v; _apply(); },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f = _filters[i];
                          final active = f == _filter;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () { _filter = f; _apply(); },
                              borderRadius: BorderRadius.circular(kRadiusFull),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: active ? kPrimary : kBgCard,
                                  borderRadius: BorderRadius.circular(kRadiusFull),
                                  border: Border.all(color: active ? kPrimary : kBorder2),
                                ),
                                child: Center(
                                  child: Text(
                                    _labels[f]!,
                                    style: TextStyle(
                                      color: active ? Colors.white : kMuted,
                                      fontSize: 12.5,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: AppLoading()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: AppError(message: _error!, onRetry: _load)),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 48, color: kMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Tarian tidak ditemukan.',
                        style: TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 400,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _TarianGridCard(
                      tarian: _filtered[i],
                      kategoriLabel: _kategoriLabel(_filtered[i].kategori),
                      onTap: () => _detail(_filtered[i]),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
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
  final Tarian tarian;
  final String kategoriLabel;
  final VoidCallback onTap;
  const _TarianGridCard({
    required this.tarian,
    required this.kategoriLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBgCard,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      url: tarian.foto,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: kPrimaryPale,
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logosanggar.png',
                            color: Colors.white.withOpacity(0.4),
                            colorBlendMode: BlendMode.modulate,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(kRadiusFull),
                        ),
                        child: Text(
                          kategoriLabel,
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.02,
                          ),
                        ),
                      ),
                    ),
                    if (tarian.unggulan)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kGold.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(kRadiusFull),
                          ),
                          child: const Text(
                            'Unggulan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarian.nama,
                        style: TextStyle(
                          color: kDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: kMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tarian.asal,
                              style: TextStyle(
                                color: kMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

  String? _getYtThumb(String? url) {
    if (url == null || url.isEmpty) return null;
    final id = YoutubePlayer.convertUrlToId(url);
    if (id != null) return YoutubePlayer.getThumbnail(videoId: id);
    return null;
  }

  Future<void> _launchYt(BuildContext context, String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka video.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getYtThumb(tarian.videoUrl) ?? tarian.foto;
    final hasVideo = tarian.videoUrl != null && tarian.videoUrl!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize:     0.95,
      minChildSize:     0.45,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        kBgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
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
              // Hero image atau Youtube Thumbnail
              GestureDetector(
                onTap: () {
                  if (hasVideo) _launchYt(context, tarian.videoUrl!);
                },
                child: Stack(children: [
                  AppImage(
                    url:    imageUrl,
                    height: 240,
                    width:  double.infinity,
                    // 🛠 ...
                    placeholder: Container(
                      height: 240, 
                      color: kPrimaryPale,
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logosanggar.png',
                          color: Colors.white.withOpacity(0.5),
                          colorBlendMode: BlendMode.modulate,
                        ),
                      ),
                    ),
                  ),
                  if (hasVideo)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                        ),
                      ),
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
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(kSpace, 4, kSpace, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CategoryChip(tarian.kategori),
                    if (tarian.unggulan) ...[
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 12),
                  Text(tarian.nama, style: AppText.displayLg),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 14, color: kMuted),
                    const SizedBox(width: 4),
                    Text(tarian.asal, style: AppText.bodySm),
                  ]),
                  const SizedBox(height: kSpace),

                  // Divider ornamental
                  Row(children: [
                    Container(width: 32, height: 2, color: kPrimary),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 2, color: kPrimaryLight),
                  ]),
                  const SizedBox(height: kSpace),

                  Text(tarian.deskripsi,
                    style: AppText.bodyMd.copyWith(height: 1.75)),

                  // Info cards
                  const SizedBox(height: kSpaceMd),
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

                  if (hasVideo) ...[
                    const SizedBox(height: kSpace),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchYt(context, tarian.videoUrl!),
                        icon:  const Icon(Icons.play_circle_rounded, size: 20),
                        label: const Text('Tonton Video Tarian'),
                      ),
                    ),
                  ],
                  const SizedBox(height: kSpaceXl),
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
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption.copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: AppText.label),
      ])),
    ]),
  );
}