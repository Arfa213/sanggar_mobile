// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'auth/login_screen.dart';

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

// ── GUEST ────────────────────────────────────────────────────
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

            // Illustration
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape:  BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 54),
            ),
            const SizedBox(height: kSpaceLg),

            const AppBadge('AKUN ANGGOTA'),
            const SizedBox(height: 12),
            Text('Masuk ke Akun Anda', style: AppText.displayMd),
            const SizedBox(height: 8),
            Text(
              'Masuk atau daftar untuk mengakses fitur lengkap dan mengikuti kegiatan sanggar.',
              style: AppText.bodySm,
              textAlign: TextAlign.center),
            const SizedBox(height: kSpaceXl),

            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Masuk Sekarang'),
              )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(showRegister: true))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side:  const BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusFull)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Daftar Anggota',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )),
          ]),
        ),
      ),
    );
  }
}

// ── LOGGED IN ────────────────────────────────────────────────
class _LoggedInView extends StatelessWidget {
  final AuthProvider auth;
  const _LoggedInView({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: kBgSoft,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: kPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryDark, kPrimary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Stack(children: [
                Positioned(top: -30, right: -30,
                  child: Container(width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 30)))),
                SafeArea(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(initial, style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))),
                    const SizedBox(height: 10),
                    Text(user.name, style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                )),
              ]),
            ),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          const SizedBox(height: kSpace),

          // Role badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpace),
            child: Container(
              padding: const EdgeInsets.all(kSpace),
              decoration: BoxDecoration(
                color:        kBgCard,
                borderRadius: BorderRadius.circular(kRadius),
                border:       Border.all(color: kBorder2)),
              child: Row(children: [
                AppBadge(
                  user.isAdmin ? '👑 Administrator' : '🎭 Anggota'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: user.status == 'aktif'
                        ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(kRadiusFull)),
                  child: Text(
                    user.status == 'aktif' ? '● Aktif' : '○ Non-aktif',
                    style: TextStyle(
                      color: user.status == 'aktif'
                          ? const Color(0xFF2E7D32) : kMuted,
                      fontSize: 11, fontWeight: FontWeight.w800))),
              ])),
          ),
          const SizedBox(height: kSpaceSm),

          _MenuItem(Icons.person_outline_rounded, 'Edit Profil', () {}),
          _MenuItem(Icons.lock_outline_rounded,   'Ubah Password', () {}),
          _MenuItem(Icons.history_rounded,         'Riwayat Aktivitas', () {}),
          _MenuItem(Icons.info_outline_rounded,    'Tentang Aplikasi', () {}),
          _MenuItem(Icons.help_outline_rounded,    'Pusat Bantuan', () {}),

          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace, kSpace, kSpace, 0),
            child: OutlinedButton.icon(
              onPressed: () => auth.logout(),
              icon:  const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
              label: const Text('Keluar',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize:  const Size.fromHeight(50),
                side:         const BorderSide(color: Colors.red),
                shape:        RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius)),
              ),
            ),
          ),
          const SizedBox(height: 90),
        ])),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: kSpace, vertical: 3),
    child: Material(color: kBgCard,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: kSpace, vertical: 15),
          decoration: BoxDecoration(
            border:       Border.all(color: kBorder2),
            borderRadius: BorderRadius.circular(kRadius)),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color:        kPrimaryPale,
                borderRadius: BorderRadius.circular(kRadiusSm)),
              child: Icon(icon, color: kPrimary, size: 18)),
            const SizedBox(width: 12),
            Text(label, style: AppText.label),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: kMuted2, size: 18),
          ]),
        ),
      ),
    ),
  );
}