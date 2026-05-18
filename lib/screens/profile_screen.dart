// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'auth/login_screen.dart';
import 'profil/edit_profil_screen.dart';
import 'profil/edit_password_screen.dart';
import 'profil/riwayat_screen.dart';
import 'profil/pusat_bantuan_scren.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) return const Scaffold(body: AppLoading());
    if (!auth.isLoggedIn) return const _GuestView();
    return _LoggedInView(auth: auth);
  }
}

// ── GUEST ─────────────────────────────────────────────────────
class _GuestView extends StatelessWidget {
  const _GuestView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kSpaceLg),
          child: Column(children: [
            const SizedBox(height: kSpaceXl),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 58),
            ),
            const SizedBox(height: kSpaceLg),
            const AppBadge('AKUN ANGGOTA'),
            const SizedBox(height: 12),
            Text('Masuk ke Akun Anda', style: AppText.displayMd),
            const SizedBox(height: 8),
            Text('Masuk atau daftar untuk mengakses fitur lengkap dan mengikuti kegiatan sanggar.',
                style: AppText.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: kSpaceXl),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Masuk Sekarang'))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(showRegister: true))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary, side: const BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusFull)),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Daftar Anggota', style: TextStyle(fontWeight: FontWeight.w700)))),
          ]),
        ),
      ),
    );
  }
}

// ── LOGGED IN ─────────────────────────────────────────────────
class _LoggedInView extends StatelessWidget {
  final AuthProvider auth;
  const _LoggedInView({required this.auth});

  Future<void> _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLg)),
      title: const Text('Keluar dari Akun?'),
      content: const Text('Kamu akan keluar dari akun sanggar saat ini.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: kMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ],
    ));
    if (ok == true) {
      await auth.logout();
      if (!ctx.mounted) return;
      Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    return Scaffold(
      backgroundColor: kBgSoft,
      body: CustomScrollView(slivers: [
        // ── Header ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: kPrimary,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [kPrimaryDark, kPrimary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Stack(children: [
                Positioned(top: -30, right: -30,
                  child: Container(width: 180, height: 180,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.06), width: 30)))),
                SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Stack(children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3)),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: (user.foto != null && user.foto!.isNotEmpty)
                            ? NetworkImage(getImageUrl(user.foto!)) as ImageProvider : null,
                        child: (user.foto == null || user.foto!.isEmpty)
                            ? Text(user.initial, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900))
                            : null,
                      ),
                    ),
                    Positioned(bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13))),
                  ]),
                  const SizedBox(height: 10),
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ]))),
              ]),
            ),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          const SizedBox(height: kSpace),

          // Role badge
          Padding(padding: const EdgeInsets.symmetric(horizontal: kSpace),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kBorder2)),
              child: Row(children: [
                AppBadge(user.isAdmin ? '👑 Administrator' : '🎭 Anggota Sanggar'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.status == 'aktif' ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(kRadiusFull)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle,
                        color: user.status == 'aktif' ? const Color(0xFF2E7D32) : kMuted)),
                    const SizedBox(width: 5),
                    Text(user.status == 'aktif' ? 'Aktif' : 'Non-aktif',
                        style: TextStyle(color: user.status == 'aktif' ? const Color(0xFF2E7D32) : kMuted,
                            fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
            )),
          const SizedBox(height: kSpaceMd),

          _sectionTitle('PENGATURAN AKUN'),
          _MenuItem(Icons.person_outline_rounded, 'Edit Profil',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
          _MenuItem(Icons.lock_outline_rounded, 'Ubah Password',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
          _MenuItem(Icons.history_rounded, 'Riwayat Aktivitas',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()))),

          const SizedBox(height: kSpace),
          _sectionTitle('INFORMASI'),
          _MenuItem(Icons.info_outline_rounded, 'Tentang Aplikasi', () => _showAbout(context)),
          _MenuItem(Icons.help_outline_rounded, 'Pusat Bantuan',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),

          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace, kSpaceLg, kSpace, 0),
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
              label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
                backgroundColor: const Color(0xFFFFEBEE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ])),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(kSpace + 4, 4, kSpace, 8),
    child: Text(t, style: AppText.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)));

  void _showAbout(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLg))),
    backgroundColor: kBgCard,
    builder: (_) => Padding(padding: const EdgeInsets.all(kSpaceLg),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder2, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Tentang Aplikasi', style: AppText.displayXs),
        const SizedBox(height: 10),
        Text('Aplikasi Sanggar Mulya Bhakti — platform digitalisasi arsip kebudayaan seni tari khas Indramayu dan manajemen keanggotaan sanggar.',
            style: AppText.bodyMd.copyWith(color: kMuted, height: 1.6)),
        const SizedBox(height: 16),
        const Divider(color: kBorder),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Versi Aplikasi', style: AppText.bodySm),
          Text('v1.1.0', style: AppText.label.copyWith(color: kPrimary)),
        ]),
        const SizedBox(height: 20),
      ])));
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: kSpace, vertical: 3),
    child: Material(color: kBgCard, borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: kBorder2), borderRadius: BorderRadius.circular(kRadius)),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: kPrimaryPale, borderRadius: BorderRadius.circular(kRadiusSm)),
              child: Icon(icon, color: kPrimary, size: 18)),
            const SizedBox(width: 14),
            Text(label, style: AppText.label.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: kMuted2, size: 20),
          ]),
        ),
      ),
    ),
  );
}