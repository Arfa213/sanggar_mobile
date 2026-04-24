// lib/widgets/stat_card.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  const StatCard({super.key, required this.number, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: kPrimaryPale, shape: BoxShape.circle),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(number, style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900, color: kDark, fontFamily: 'serif')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }
}