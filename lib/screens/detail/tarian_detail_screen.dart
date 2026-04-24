// lib/screens/detail/tarian_detail_screen.dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/api_service.dart';

class TarianDetailScreen extends StatefulWidget {
  final int tarianId;
  final Tarian? tarianData; // opsional, kalau sudah ada datanya
  const TarianDetailScreen({super.key, required this.tarianId, this.tarianData});
  @override State<TarianDetailScreen> createState() => _TarianDetailScreenState();
}

class _TarianDetailScreenState extends State<TarianDetailScreen> {
  Tarian? _tarian;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.tarianData != null) {
      _tarian = widget.tarianData;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final t = await ApiService.getTarianDetail(widget.tarianId);
      if (!mounted) return;
      setState(() { _tarian = t; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: _loading
          ? const AppLoading()
          : _tarian == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() => Scaffold(
    appBar: AppBar(),
    body: const Center(child: Text('Gagal memuat data tarian.')),
  );

  Widget _buildContent() {
    final t = _tarian!;
    return CustomScrollView(slivers: [
      // Hero image AppBar
      SliverAppBar(
        expandedHeight: 280,
        pinned: true,
        backgroundColor: kPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(fit: StackFit.expand, children: [
            AppImage(
              url: t.foto,
              fit: BoxFit.cover,
              placeholder: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryDark, kPrimary],
                    begin: Alignment.topLeft, end: Alignment.bottomRight))),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
            ),
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CategoryChip(t.kategori),
                  if (t.unggulan) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGold.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(kRadiusFull)),
                      child: const Text('★ Unggulan',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                  ],
                ]),
                const SizedBox(height: 8),
                Text(t.nama, style: AppText.displayLg.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(t.asal, style: AppText.bodySm.copyWith(color: Colors.white70)),
                ]),
              ]),
            ),
          ]),
        ),
      ),

      SliverList(delegate: SliverChildListDelegate([
        // Quick info strip
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: kSpace, vertical: kSpaceMd),
          child: Row(children: [
            if (t.durasi != null) ...[
              _InfoChip(Icons.schedule_rounded, t.durasi!),
              const SizedBox(width: kSpace),
            ],
            _InfoChip(Icons.category_rounded, t.kategori),
            const Spacer(),
            if (t.videoUrl != null)
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimary, borderRadius: BorderRadius.circular(kRadiusFull)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.play_circle_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Video', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ]),
        ),
        const AppDivider(padding: EdgeInsets.zero),

        // Deskripsi
        Padding(
          padding: const EdgeInsets.all(kSpace),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ornamental divider
            Row(children: [
              Container(width: 32, height: 2.5, color: kPrimary),
              const SizedBox(width: 6),
              Container(width: 10, height: 2.5, color: kPrimaryLight),
              const SizedBox(width: 6),
              Container(width: 4, height: 2.5, color: kPrimaryPale2),
            ]),
            const SizedBox(height: kSpace),
            Text(t.deskripsi, style: AppText.bodyMd.copyWith(height: 1.8)),
          ]),
        ),

        // Info detail
        if (t.fungsi != null || t.kostum != null)
        Container(
          margin: const EdgeInsets.fromLTRB(kSpace, 0, kSpace, kSpace),
          padding: const EdgeInsets.all(kSpace),
          decoration: BoxDecoration(
            color: kBgSoft,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder2)),
          child: Column(children: [
            if (t.fungsi != null) ...[
              _DetailRow('🎭', 'Fungsi Tarian', t.fungsi!),
              if (t.kostum != null) const AppDivider(),
            ],
            if (t.kostum != null) _DetailRow('👘', 'Kostum & Properti', t.kostum!),
          ]),
        ),

        // CTA daftar kelas
        Container(
          margin: const EdgeInsets.fromLTRB(kSpace, 0, kSpace, kSpace),
          padding: const EdgeInsets.all(kSpaceMd),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(kRadius)),
          child: Column(children: [
            const Text('Tertarik mempelajari tarian ini?',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 6),
            Text('Daftar kelas dan dapatkan jadwal latihan otomatis',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              textAlign: TextAlign.center),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/penjadwalan',
                    arguments: {'tarian': t}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Daftar Kelas Ini',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              )),
          ]),
        ),

        const SizedBox(height: 80),
      ])),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoChip(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: kMuted),
    const SizedBox(width: 4),
    Text(text, style: AppText.bodySm),
  ]);
}

class _DetailRow extends StatelessWidget {
  final String emoji, label, value;
  const _DetailRow(this.emoji, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption.copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(value, style: AppText.label),
      ])),
    ]),
  );
}