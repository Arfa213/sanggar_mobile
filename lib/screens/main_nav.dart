// lib/screens/main_nav.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'archive_screen.dart';
import 'penjadwalan_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  static _MainNavState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainNavState>();
  @override State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _idx = 0;
  set setIndex(int i) => setState(() => _idx = i);

  final _pages = const [HomeScreen(), PenjadwalanScreen(), ArchiveScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Proteksi halaman: Jika user tidak terdeteksi login, langsung lempar kembali ke halaman login
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Beranda', idx: 0, cur: _idx, onTap: (i) => setState(() => _idx = i)),
                _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Jadwal', idx: 1, cur: _idx, onTap: (i) => setState(() => _idx = i)),
                _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Materi', idx: 2, cur: _idx, onTap: (i) => setState(() => _idx = i)),
                _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil', idx: 3, cur: _idx, onTap: (i) => setState(() => _idx = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int idx, cur;
  final void Function(int) onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.idx,
    required this.cur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = idx == cur;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(idx),
          borderRadius: BorderRadius.circular(8),
          splashColor: kPrimary.withOpacity(0.08),
          highlightColor: kPrimary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? kPrimary : kMuted,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? kPrimary : kMuted,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
