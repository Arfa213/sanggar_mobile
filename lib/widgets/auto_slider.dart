// lib/widgets/auto_slider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../utils/app_theme.dart';

class AutoSlider extends StatefulWidget {
  final List<SlideItem> items;
  final double          height;
  final Duration        interval;

  const AutoSlider({
    super.key,
    required this.items,
    this.height   = 300,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<AutoSlider> createState() => _AutoSliderState();
}

class _AutoSliderState extends State<AutoSlider> {
  late PageController _ctrl;
  late Timer          _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 1);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || widget.items.isEmpty) return;
      final next = (_current + 1) % widget.items.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve:    Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return _placeholderSlide();

    return SizedBox(
      height: widget.height,
      child: Stack(children: [
        // PageView
        PageView.builder(
          controller: _ctrl,
          itemCount:  widget.items.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => _SlideCard(item: widget.items[i]),
        ),

        // Dot indicator
        Positioned(
          bottom: 18,
          left:   0, right: 0,
          child: Center(
            child: SmoothPageIndicator(
              controller: _ctrl,
              count:      widget.items.length,
              effect: WormEffect(
                dotWidth:     8,
                dotHeight:    8,
                spacing:      6,
                dotColor:     Colors.white.withOpacity(0.4),
                activeDotColor: Colors.white,
                type:         WormType.thin,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _placeholderSlide() => Container(
    height: widget.height,
    decoration: const BoxDecoration(
      color: kPrimary,
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Sanggar Mulya Bhakti',
        style: AppText.displayMd.copyWith(color: Colors.white)),
      const SizedBox(height: 8),
      Text('Melestarikan Budaya Melalui Seni',
        style: AppText.bodyMd.copyWith(color: Colors.white70)),
    ]),
  );
}

class _SlideCard extends StatelessWidget {
  final SlideItem item;
  const _SlideCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Gambar
      item.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: item.imageUrl!,
              fit:      BoxFit.cover,
              placeholder: (_, __) => Container(color: kPrimaryDark),
              errorWidget: (_, __, ___) => _colorBg(),
            )
          : _colorBg(),

      // Gradient overlay
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.25),
              Colors.black.withOpacity(0.72),
            ],
            stops: const [0.35, 0.65, 1.0],
          ),
        ),
      ),

      // Konten teks
      Positioned(
        left: 24, right: 24, bottom: 44,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            if (item.badge != null)
              Container(
                margin:  const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(kRadiusFull),
                  border:       Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(item.badge!,
                  style: const TextStyle(
                    color:       Colors.white,
                    fontSize:    10,
                    fontWeight:  FontWeight.w700,
                    letterSpacing: 1.2,
                  )),
              ),
            if (item.title != null)
              Text(item.title!,
                style: AppText.displayMd.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1), blurRadius: 4),
                  ],
                )),
            if (item.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(item.subtitle!,
                style: AppText.bodySm.copyWith(color: Colors.white70)),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _colorBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [kPrimaryDark, kPrimary],
        begin:  Alignment.topLeft,
        end:    Alignment.bottomRight,
      ),
    ),
  );
}

// ── DATA MODEL ───────────────────────────────────────────────
class SlideItem {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? badge;

  const SlideItem({
    this.imageUrl,
    this.title,
    this.subtitle,
    this.badge,
  });
}