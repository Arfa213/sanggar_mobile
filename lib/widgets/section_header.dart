import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMore;
  const SectionHeader({super.key, required this.title, this.subtitle, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: kDark, fontFamily: 'serif')),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: kMuted)),
        ])),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Lihat semua', style: TextStyle(color: kPrimary, fontSize: 12)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: kPrimary, size: 16),
            ]),
          ),
      ]),
    );
  }
}