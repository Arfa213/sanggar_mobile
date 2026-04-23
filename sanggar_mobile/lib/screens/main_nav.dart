// lib/screens/main_nav.dart — VERSI UPDATE
// Perubahan: + tombol chatbot FAB, + navigasi ke detail screens

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'event_screen.dart';
import 'archive_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import 'penjadwalan_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _idx = 0;

  static const _screens = [
    HomeScreen(),
    EventScreen(),
    ArchiveScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),

      // ── CHATBOT FAB ──────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        backgroundColor: kPrimary,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
      ),

      bottomNavigationBar: _BottomNav(
        currentIndex: _idx,
        onTap:        (i) => setState(() => _idx = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded,          label: 'Beranda'),
    _NavItem(icon: Icons.event_rounded,          label: 'Event'),
    _NavItem(icon: Icons.library_music_rounded,  label: 'Arsip'),
    _NavItem(icon: Icons.person_rounded,         label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:     kBgCard,
        border:    const Border(top: BorderSide(color: kBorder2)),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(0.07),
          blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              // Beri ruang kosong di tengah untuk FAB
              if (i == 2) {
                return Expanded(child: Row(children: [
                  _NavTile(item: _items[i], active: i == currentIndex, onTap: () => onTap(i)),
                  const SizedBox(width: 44), // spacer FAB
                ]));
              }
              return _NavTile(
                item:   _items[i],
                active: i == currentIndex,
                onTap:  () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool     active;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
              horizontal: active ? 12 : 8, vertical: 5),
          decoration: BoxDecoration(
            color:        active ? kPrimaryPale : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusFull)),
          child: Icon(item.icon, size: 22, color: active ? kPrimary : kMuted),
        ),
        const SizedBox(height: 2),
        Text(item.label, style: TextStyle(
          fontSize:   10,
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          color:      active ? kPrimary : kMuted,
          letterSpacing: active ? 0.2 : 0)),
      ]),
    ),
  );
}