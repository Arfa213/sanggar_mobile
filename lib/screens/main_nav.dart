// lib/screens/main_nav.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'archive_screen.dart';
import 'event_screen.dart';
import 'profile_screen.dart';
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

  final _pages = const [HomeScreen(), ArchiveScreen(), EventScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBgCard,
          border: const Border(top: BorderSide(color: Color(0xFFF0EBE5), width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              _NavItem(icon: Icons.home_rounded,   label: 'Beranda', idx: 0, cur: _idx, onTap: (i) => setState(() => _idx = i)),
              _NavItem(icon: Icons.library_music_rounded, label: 'Arsip', idx: 1, cur: _idx, onTap: (i) => setState(() => _idx = i)),
              _NavItem(icon: Icons.event_rounded,  label: 'Event',   idx: 2, cur: _idx, onTap: (i) => setState(() => _idx = i)),
              _NavItem(icon: Icons.person_rounded, label: 'Profil',  idx: 3, cur: _idx, onTap: (i) => setState(() => _idx = i)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx, cur;
  final void Function(int) onTap;
  const _NavItem({required this.icon, required this.label, required this.idx, required this.cur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = idx == cur;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? kPrimaryPale : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: active ? kPrimary : kMuted2, size: active ? 24 : 22),
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              color: active ? kPrimary : kMuted2,
              fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            )),
          ]),
        ),
      ),
    );
  }
}