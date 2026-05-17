// lib/screens/main_nav.dart
import 'package:flutter/material.dart';
import 'package:sanggar_mulya_bhakti/screens/event_screen.dart';
import 'home_screen.dart';
import 'archive_screen.dart'; // FIX: Menggunakan file ArchiveScreen Anda
import 'profile_screen.dart';
import '../utils/app_theme.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  // Fungsi statis agar HomeScreen bisa mengakses State dari MainNav
  static _MainNavState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainNavState>();

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  // Setter untuk mengubah tab aktif secara dinamis dari luar kelas
  set setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Daftar halaman utama pada Bottom Navigation Bar
  final List<Widget> _children = [
    const HomeScreen(),
    const ArchiveScreen(), // Indeks 1: Halaman Arsip 
    const EventScreen(), // Indeks 2: Halaman Event
    const ProfileScreen(), // Indeks 3: Halaman Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: kPrimary,
        unselectedItemColor: kMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Arsip'),
          BottomNavigationBarItem(icon: Icon(Icons.event_rounded), label: 'Event'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}