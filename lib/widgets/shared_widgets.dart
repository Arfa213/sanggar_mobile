// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';

// ── BADGE ────────────────────────────────────────────────────
class AppBadge extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? color;
  const AppBadge(this.text, {super.key, this.bg, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color:        bg ?? kPrimaryPale,
        borderRadius: BorderRadius.circular(kRadiusFull),
        border:       Border.all(color: (color ?? kPrimary).withOpacity(0.25)),
      ),
      child: Text(text, style: AppText.caption.copyWith(
        color:         color ?? kPrimary,
        letterSpacing: 1.2,
        fontWeight:    FontWeight.w800,
      )),
    );
  }
}

// ── SECTION HEADER ───────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpace, kSpaceLg, kSpace, kSpaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (subtitle != null)
                Text(subtitle!, style: AppText.caption.copyWith(
                  color: kPrimary, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(title, style: AppText.displayXs),
            ]),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(actionLabel!,
                  style: AppText.bodySm.copyWith(
                    color: kPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: kPrimary),
              ]),
            ),
        ],
      ),
    );
  }
}

// ── STAT ITEM ────────────────────────────────────────────────
class StatItem extends StatelessWidget {
  final String number;
  final String label;
  final IconData? icon;

  const StatItem({
    super.key,
    required this.number,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color:        kBgCard,
          borderRadius: BorderRadius.circular(kRadius),
          border:       Border.all(color: kBorder2),
          boxShadow: [
            BoxShadow(
              color:       kPrimary.withOpacity(0.06),
              blurRadius:  12,
              offset:      const Offset(0, 4),
            ),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: kPrimaryPale, shape: BoxShape.circle),
              child: Icon(icon, color: kPrimary, size: 18),
            ),
            const SizedBox(height: 8),
          ],
          Text(number,
            style: AppText.displaySm.copyWith(
              color: kPrimary, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label,
            style: AppText.caption,
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── NETWORK IMAGE ────────────────────────────────────────────
class AppImage extends StatelessWidget {
  final String?  url;
  final double?  width;
  final double?  height;
  final BoxFit   fit;
  final BorderRadius? borderRadius;
  final Widget?  placeholder;

  const AppImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (url == null || url!.isEmpty) {
      child = placeholder ?? _defaultPlaceholder();
    } else {
      child = CachedNetworkImage(
        imageUrl:    url!,
        width:       width,
        height:      height,
        fit:         fit,
        placeholder: (_, __) => _shimmer(),
        errorWidget: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor:      const Color(0xFFEDE8E3),
    highlightColor: kBgSoft,
    child: Container(
      width: width, height: height,
      color: Colors.white,
    ),
  );

  Widget _defaultPlaceholder() => Container(
    width: width, height: height,
    color: kPrimaryPale,
    child: const Center(
      child: Icon(Icons.image_outlined, color: kPrimary, size: 32)),
  );
}

// ── CATEGORY CHIP ────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final String kategori;
  final bool   small;
  const CategoryChip(this.kategori, {super.key, this.small = false});

  static const _bg = {
    'sakral':      Color(0xFFE8F5E9),
    'hiburan':     Color(0xFFE8F4FD),
    'penyambutan': Color(0xFFFCE4EC),
    'ritual':      Color(0xFFEDE7F6),
    'perang':      Color(0xFFFBE9E7),
    'internasional': Color(0xFFE8F4FD),
    'nasional':    Color(0xFFE8F5E9),
    'festival':    Color(0xFFFFF3E0),
    'pentas':      Color(0xFFF3E5F5),
    'kompetisi':   Color(0xFFFFF8E1),
  };
  static const _fg = {
    'sakral':      Color(0xFF2E7D32),
    'hiburan':     Color(0xFF1565C0),
    'penyambutan': Color(0xFF880E4F),
    'ritual':      Color(0xFF4527A0),
    'perang':      Color(0xFFBF360C),
    'internasional': Color(0xFF1565C0),
    'nasional':    Color(0xFF2E7D32),
    'festival':    Color(0xFFE65100),
    'pentas':      Color(0xFF6A1B9A),
    'kompetisi':   Color(0xFFF57F17),
  };

  static const _emoji = {
    'sakral': '🌿', 'hiburan': '🎭', 'penyambutan': '🌺',
    'ritual': '🔥', 'perang': '⚔️', 'internasional': '🌏',
    'nasional': '🇮🇩', 'festival': '🎪', 'pentas': '🎤', 'kompetisi': '🏆',
  };

  @override
  Widget build(BuildContext context) {
    final bg  = _bg[kategori]    ?? kPrimaryPale;
    final fg  = _fg[kategori]    ?? kPrimary;
    final em  = _emoji[kategori] ?? '🎭';
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 5);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(kRadiusFull),
      ),
      child: Text(
        small ? kategori : '$em  $kategori',
        style: TextStyle(
          color:       fg,
          fontSize:    small ? 9 : 11,
          fontWeight:  FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── DIVIDER ──────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  final EdgeInsets padding;
  const AppDivider({super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: kSpace)});

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: const Divider(color: kBorder2, height: 1, thickness: 1),
  );
}

// ── LOADING ──────────────────────────────────────────────────
class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircularProgressIndicator(color: kPrimary, strokeWidth: 2.5),
      if (message != null) ...[
        const SizedBox(height: 12),
        Text(message!, style: AppText.bodySm),
      ],
    ],
  ));
}

// ── ERROR VIEW ───────────────────────────────────────────────
class AppError extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const AppError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(kSpaceXl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: kPrimaryPale, borderRadius: BorderRadius.circular(kRadius)),
          child: const Icon(Icons.wifi_off_rounded, color: kPrimary, size: 32),
        ),
        const SizedBox(height: kSpace),
        Text('Koneksi Bermasalah',
          style: AppText.displayXs.copyWith(fontSize: 18)),
        const SizedBox(height: 6),
        Text(
          'Pastikan Laravel berjalan dan URL sudah benar di constants.dart',
          style: AppText.bodySm,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kSpaceLg),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon:  const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Coba Lagi'),
        ),
      ]),
    ),
  );
}