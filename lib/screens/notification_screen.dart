// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = context.watch<NotificationService>();
    final list = notifService.notifications;

    // Kelompokkan notifikasi
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final hariIni = <AppNotification>[];
    final groupedByMonth = <String, List<AppNotification>>{};

    const monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    for (var n in list) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      if (d == today) {
        hariIni.add(n);
      } else {
        final monthStr = '${monthNames[n.timestamp.month]} ${n.timestamp.year}';
        if (!groupedByMonth.containsKey(monthStr)) {
          groupedByMonth[monthStr] = [];
        }
        groupedByMonth[monthStr]!.add(n);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFC84B31)), // kPrimary
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: list.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                if (hariIni.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Hari ini', notifService, showMarkAll: true),
                  ...hariIni.map((n) => _NotificationCard(notif: n, service: notifService)),
                  const SizedBox(height: 10),
                ],
                ...groupedByMonth.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(context, entry.key, notifService),
                      ...entry.value.map((n) => _NotificationCard(notif: n, service: notifService)),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, NotificationService service, {bool showMarkAll = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E), // kDark
            ),
          ),
          if (showMarkAll)
            GestureDetector(
              onTap: () {
                service.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(
                  color: Color(0xFFC84B31), // kPrimary
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFBECE9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFFC84B31),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Notifikasi',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pemberitahuan jadwal latihan dan pengingat akan muncul di sini!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notif;
  final NotificationService service;

  const _NotificationCard({required this.notif, required this.service});

  @override
  Widget build(BuildContext context) {
    // Styling berdasarkan tipe dan status isRead
    final isUnread = !notif.isRead;
    
    // Warna untuk state unread vs read
    final iconBgColor = isUnread ? const Color(0xFFFDECE5) : const Color(0xFFEEEEEE);
    final iconColor = isUnread ? const Color(0xFFC84B31) : const Color(0xFF757575);

    // Tentukan icon berdasarkan tipe
    IconData getIcon() {
      if (notif.title.toLowerCase().contains('jadwal')) return Icons.calendar_month_rounded;
      if (notif.title.toLowerCase().contains('materi')) return Icons.menu_book_rounded;
      if (notif.title.toLowerCase().contains('bayar')) return Icons.credit_card_rounded;
      if (notif.title.toLowerCase().contains('pentas')) return Icons.event_available_rounded;
      
      switch (notif.type) {
        case 'reminder': return Icons.event_note_rounded;
        case 'approval': return Icons.check_circle_outline_rounded;
        case 'announcement': return Icons.campaign_rounded;
        default: return Icons.notifications_none_rounded;
      }
    }

    final timeStr = _formatTimestamp(notif.timestamp);

    // Cek apakah judul mengandung 'Materi' untuk menampilkan tombol khusus (seperti di gambar)
    final hasMateriButton = notif.title.toLowerCase().contains('materi');

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          service.markAsRead(notif.id);
        }
        _showDetailBottomSheet(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isUnread ? const Color(0xFFC84B31) : Colors.transparent,
                width: isUnread ? 4 : 0,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(getIcon(), color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    
                    // Tombol khusus "Lihat Materi" seperti di gambar
                    if (hasMateriButton) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          if (!notif.isRead) service.markAsRead(notif.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC84B31),
                          side: const BorderSide(color: Color(0xFFC84B31), width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          minimumSize: const Size(0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Lihat\nMateri',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    
    if (date == today) {
      final diff = now.difference(dt);
      if (diff.inHours < 1) {
        if (diff.inMinutes <= 0) return 'Baru saja';
        return '${diff.inMinutes} menit lalu';
      }
      return '${diff.inHours} jam lalu';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMM').format(dt);
    }
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFC84B31), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notif.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            Text(
              notif.message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Diterima: ${DateFormat('dd MMMM yyyy, HH:mm').format(notif.timestamp)} WIB',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC84B31),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
