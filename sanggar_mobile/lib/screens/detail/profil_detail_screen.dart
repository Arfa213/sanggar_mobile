// lib/screens/detail/profil_detail_screen.dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class ProfilDetailScreen extends StatelessWidget {
  final SanggarProfile profil;
  const ProfilDetailScreen({super.key, required this.profil});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: CustomScrollView(slivers: [
        // AppBar dengan gambar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: kPrimary,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              profil.fotoProfil != null
                  ? AppImage(url: profil.fotoProfil, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryDark, kPrimary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)])),
              ),
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppBadge('TENTANG SANGGAR'),
                  const SizedBox(height: 8),
                  Text(profil.namaSanggar, style: AppText.displayMd.copyWith(color: Colors.white)),
                  if (profil.tahunBerdiri != null)
                    Text('Berdiri sejak ${profil.tahunBerdiri}',
                      style: AppText.bodySm.copyWith(color: Colors.white70)),
                ]),
              ),
            ]),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          // Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(kSpace),
            child: Row(children: [
              _StatBox('${profil.jumlahAnggota}+', 'Anggota'),
              Container(width: 1, height: 40, color: kBorder2),
              _StatBox('${profil.jumlahPenghargaan}+', 'Penghargaan'),
              Container(width: 1, height: 40, color: kBorder2),
              _StatBox('${profil.jumlahEvent}+', 'Event'),
            ]),
          ),
          const AppDivider(padding: EdgeInsets.zero),

          // Sejarah
          _Section(
            icon: Icons.history_edu_rounded,
            title: 'Sejarah Sanggar',
            child: Text(profil.sejarah, style: AppText.bodyMd.copyWith(height: 1.75)),
          ),

          // Visi
          if (profil.visi.isNotEmpty)
          _Section(
            icon: Icons.visibility_rounded,
            title: 'Visi',
            child: Container(
              padding: const EdgeInsets.all(kSpace),
              decoration: BoxDecoration(
                color: kPrimaryPale,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: kPrimary.withOpacity(0.2))),
              child: Text(profil.visi,
                style: AppText.bodyMd.copyWith(
                  color: kPrimaryDark, fontStyle: FontStyle.italic, height: 1.7)),
            ),
          ),

          // Misi
          if (profil.misi.isNotEmpty)
          _Section(
            icon: Icons.flag_rounded,
            title: 'Misi',
            child: Column(
              children: profil.misi.asMap().entries.map((e) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                      child: Center(child: Text('${e.key + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e.value, style: AppText.bodyMd.copyWith(height: 1.6)),
                    )),
                  ]),
                ),
              ).toList(),
            ),
          ),

          // Kontak
          if (profil.alamat != null || profil.noHp != null || profil.email != null)
          _Section(
            icon: Icons.contact_phone_rounded,
            title: 'Kontak & Lokasi',
            child: Column(children: [
              if (profil.alamat != null) _ContactRow(Icons.location_on_rounded, profil.alamat!),
              if (profil.noHp   != null) _ContactRow(Icons.phone_rounded,       profil.noHp!),
              if (profil.email  != null) _ContactRow(Icons.email_rounded,        profil.email!),
              if (profil.instagram != null) _ContactRow(Icons.camera_alt_rounded, profil.instagram!),
            ]),
          ),

          const SizedBox(height: 80),
        ])),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String number, label;
  const _StatBox(this.number, this.label);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(number, style: AppText.displaySm.copyWith(color: kPrimary)),
    Text(label, style: AppText.caption),
  ]));
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(kSpace, kSpaceLg, kSpace, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: kPrimaryPale, shape: BoxShape.circle),
          child: Icon(icon, color: kPrimary, size: 16)),
        const SizedBox(width: 10),
        Text(title, style: AppText.displayXs),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, color: kPrimary, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: AppText.bodyMd)),
    ]),
  );
}