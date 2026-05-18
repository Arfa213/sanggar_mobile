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

    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        iconTheme: IconThemeData(color: kText),
        title: Text(
          'Notifikasi & Pengingat',
          style: TextStyle(
            color: kText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        actions: [
          if (list.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () {
                notifService.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(Icons.done_all_rounded, color: kPrimary, size: 16),
              label: Text(
                'Baca Semua',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _confirmClear(context, notifService),
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Hapus Semua',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: kBorder2),
        ),
      ),
      body: list.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final notif = list[idx];
                return _NotificationCard(notif: notif, service: notifService);
              },
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
              decoration: BoxDecoration(
                color: kPrimaryPale,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: kPrimary,
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Belum Ada Notifikasi',
              style: TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pengingat latihan otomatis 24 jam & 1 jam sebelum sesi dimulai akan muncul di sini!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, NotificationService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Notifikasi', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Apakah Anda yakin ingin menghapus semua riwayat notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              service.clearNotifications();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('Hapus Semua'),
          ),
        ],
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
    // Styling berdasarkan tipe
    final styles = {
      'reminder': [
        const Color(0xFFFFF3E0),
        kPrimary,
        Icons.alarm_rounded,
      ],
      'approval': [
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        Icons.check_circle_outline_rounded,
      ],
      'announcement': [
        const Color(0xFFE3F2FD),
        const Color(0xFF1565C0),
        Icons.campaign_rounded,
      ],
    };

    final style = styles[notif.type] ?? [kBorder2, kMuted, Icons.notifications_rounded];
    final timeStr = _formatTimestamp(notif.timestamp);

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          service.markAsRead(notif.id);
        }
        // Tampilkan modal detail notifikasi
        _showDetailBottomSheet(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? kBgCard : const Color(0xFFFFF8F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? kBorder2 : kPrimary.withOpacity(0.2),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(notif.isRead ? 0.02 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style[0] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style[2] as IconData, color: style[1] as Color, size: 22),
            ),
            SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            color: kText,
                            fontSize: 14.5,
                            fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    notif.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: notif.isRead ? kMuted : kText.withOpacity(0.85),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: kMuted2,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 0) return 'Baru saja';
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
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
                  color: kMuted2,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: kPrimary, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notif.title,
                    style: TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'PlayfairDisplay',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: kBorder2),
            SizedBox(height: 12),
            Text(
              notif.message,
              style: TextStyle(
                color: kText,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Diterima: ${DateFormat('dd MMMM yyyy, HH:mm').format(notif.timestamp)} WIB',
              style: TextStyle(
                color: kMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
