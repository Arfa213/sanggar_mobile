// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // HTTP untuk kirim foto langsung ke Laravel
import '../services/auth_provider.dart';
import '../services/theme_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'auth/login_screen.dart';
import 'profil/edit_profil_screen.dart';
import 'profil/edit_password_screen.dart';
import 'profil/riwayat_screen.dart';
import 'profil/pusat_bantuan_scren.dart';
import 'notification_screen.dart';

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
            SizedBox(height: kSpaceXl),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 58),
            ),
            SizedBox(height: kSpaceLg),
            AppBadge('AKUN ANGGOTA'),
            SizedBox(height: 12),
            Text('Masuk ke Akun Anda', style: AppText.displayMd),
            SizedBox(height: 8),
            Text('Masuk atau daftar untuk mengakses fitur lengkap dan mengikuti kegiatan sanggar.',
                style: AppText.bodySm, textAlign: TextAlign.center),
            SizedBox(height: kSpaceXl),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text('Masuk Sekarang'))),
            SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(showRegister: true))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary, side: BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusFull)),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text('Daftar Anggota', style: TextStyle(fontWeight: FontWeight.w700)))),
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
      title: Text('Keluar dari Akun?'),
      content: Text('Kamu akan keluar dari akun sanggar saat ini.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: TextStyle(color: kMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFDECE5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'ST',
                style: TextStyle(
                  color: Color(0xFFC84B31),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Sanggar Tari',
          style: TextStyle(
            color: Color(0xFFC84B31),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.black87,
                size: 26,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Profile Picture
            GestureDetector(
              onTap: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );

                if (image != null) {
                  final file = File(image.path);
                  final fileSize = await file.length();
                  
                  if (fileSize > 5 * 1024 * 1024) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal: Ukuran foto maksimal 5MB.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await auth.uploadFoto(file);
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Foto profil berhasil diperbarui!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFEEEEEE),
                      backgroundImage: (user.foto != null && user.foto!.isNotEmpty)
                          ? NetworkImage('${getImageUrl(user.foto!)}?v=${DateTime.now().millisecondsSinceEpoch}') as ImageProvider
                          : null,
                      child: (user.foto == null || user.foto!.isEmpty)
                          ? Text(user.initial, style: const TextStyle(color: Colors.grey, fontSize: 40, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC84B31), // kPrimary
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Name
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!user.isAdmin && !user.isPengunjung) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFC84B31),
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    user.isAdmin
                        ? 'Administrator'
                        : (user.isPengunjung
                            ? 'Pengunjung'
                            : 'Anggota Tetap'),
                    style: const TextStyle(
                      color: Color(0xFFC84B31),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Menus
            _buildMenuCard(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Edit Profil',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            _buildMenuCard(
              context,
              icon: Icons.lock_outline_rounded,
              title: 'Ubah Password',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _buildMenuCard(
              context,
              icon: Icons.history_rounded,
              title: 'Riwayat Kehadiran',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryScreen())),
            ),
            _buildMenuCard(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Tentang Aplikasi',
              onTap: () => _showAbout(context),
            ),
            
            const SizedBox(height: 30),
            
            // Logout
            GestureDetector(
              onTap: () => _logout(context),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black38,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Aplikasi Sanggar Mulya Bhakti — platform digitalisasi arsip kebudayaan seni tari khas Indramayu dan manajemen keanggotaan sanggar.',
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

              const Divider(
                color: Color(0xFFEEEEEE),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Versi Aplikasi',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'v1.1.0',
                    style: TextStyle(
                      color: Color(0xFFC84B31),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

  void _showAbout(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    backgroundColor: Colors.white,
    builder: (_) => Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 24),
        const Text('Tentang Aplikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Aplikasi Sanggar Mulya Bhakti — platform digitalisasi arsip kebudayaan seni tari khas Indramayu dan manajemen keanggotaan sanggar.',
            style: TextStyle(color: Colors.black54, height: 1.6, fontSize: 14)),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFEEEEEE)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('Versi Aplikasi', style: TextStyle(fontSize: 14)),
          Text('v1.1.0', style: TextStyle(color: Color(0xFFC84B31), fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
      ]
    )
  )
);
