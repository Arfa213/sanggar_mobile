// lib/screens/detail/event_detail_screen.dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
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
                url: event.foto,
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.72)])),
              ),
              // Year ribbon
              Positioned(
                top: kSpaceLg + MediaQuery.of(context).padding.top,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: const BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(kRadius),
                      bottomRight: Radius.circular(kRadius))),
                  child: Text(event.tahun,
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CategoryChip(event.kategori),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(kRadiusFull),
                        border: Border.all(color: Colors.white.withOpacity(0.3))),
                      child: Text(event.level,
                        style: const TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                  ]),
                  const SizedBox(height: 8),
                  Text(event.nama, style: AppText.displayMd.copyWith(color: Colors.white)),
                ]),
              ),
            ]),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          // Meta info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(kSpace),
            child: Column(children: [
              _MetaRow(Icons.calendar_today_rounded, 'Tanggal',
                  '${event.tgl} ${event.bulanSingkat} ${event.tahun}'),
              const AppDivider(),
              _MetaRow(Icons.location_on_rounded, 'Lokasi', event.lokasi),
              if (event.jumlahPenonton != null) ...[
                const AppDivider(),
                _MetaRow(Icons.people_rounded, 'Penonton', '${event.jumlahPenonton}+ orang'),
              ],
            ]),
          ),
          const SizedBox(height: kSpaceSm),

          // Hasil
          if (event.hasil != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: kSpace),
            padding: const EdgeInsets.all(kSpace),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFFDE7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: kGold.withOpacity(0.4))),
            child: Row(children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Hasil Pencapaian',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: kGold, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(event.hasil!,
                  style: AppText.displayXs.copyWith(color: const Color(0xFFE65100))),
              ])),
            ]),
          ),

          // Deskripsi
          if (event.deskripsi != null)
          Padding(
            padding: const EdgeInsets.all(kSpace),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tentang Event', style: AppText.displayXs),
              const SizedBox(height: 10),
              Text(event.deskripsi!, style: AppText.bodyMd.copyWith(height: 1.75)),
            ]),
          ),

          // Penghargaan
          if (event.penghargaan.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(kSpace, 0, kSpace, kSpaceSm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Penghargaan Diraih', style: AppText.displayXs),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: event.penghargaan.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: kPrimaryPale,
                      borderRadius: BorderRadius.circular(kRadiusFull),
                      border: Border.all(color: kPrimary.withOpacity(0.25))),
                    child: Text(p, style: AppText.bodySm.copyWith(
                        color: kPrimary, fontWeight: FontWeight.w700)),
                  )).toList(),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 80),
        ])),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _MetaRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: kPrimaryPale, shape: BoxShape.circle),
        child: Icon(icon, color: kPrimary, size: 18)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption.copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: AppText.label),
      ]),
    ]),
  );
}