import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class TarianMiniCard extends StatelessWidget {
  final Tarian tarian;
  const TarianMiniCard({super.key, required this.tarian});

  static const _catColors = {
    'sakral':      Color(0xFFE8F5E9),
    'hiburan':     Color(0xFFE3F2FD),
    'penyambutan': Color(0xFFFCE4EC),
    'ritual':      Color(0xFFEDE7F6),
    'perang':      Color(0xFFFBE9E7),
  };
  static const _catTextColors = {
    'sakral':      Color(0xFF2E7D32),
    'hiburan':     Color(0xFF1565C0),
    'penyambutan': Color(0xFF880E4F),
    'ritual':      Color(0xFF4527A0),
    'perang':      Color(0xFFBF360C),
  };

  @override
  Widget build(BuildContext context) {
    final bgColor   = _catColors[tarian.kategori]   ?? kPrimaryPale;
    final textColor = _catTextColors[tarian.kategori] ?? kPrimary;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tarian.unggulan ? kPrimary : kBorder,
              width: tarian.unggulan ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: tarian.foto != null
                ? CachedNetworkImage(imageUrl: tarian.foto!,
                    height: 100, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 100, color: kPrimaryPale,
                    child: const Icon(Icons.music_note_rounded, color: kPrimary, size: 32)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(50)),
                child: Text(tarian.kategori,
                  style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Text(tarian.nama,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('📍 ${tarian.asal}',
                style: const TextStyle(fontSize: 10, color: kMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}