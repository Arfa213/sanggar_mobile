// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

bool gIsDarkMode = false;

// ── WARNA ────────────────────────────────────────────────────
const kPrimary      = Color(0xFFC65D2E);
const kPrimaryDark  = Color(0xFFA34A22);
const kPrimaryLight = Color(0xFFE07A4F);
const kGold         = Color(0xFFD4AF37);

Color get kPrimaryPale  => gIsDarkMode ? const Color(0xFF2E1A11) : const Color(0xFFFDF0EA);
Color get kPrimaryPale2 => gIsDarkMode ? const Color(0xFF3B2015) : const Color(0xFFF9E4D6);

Color get kBgSoft       => gIsDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF8F6);
Color get kBgCard       => gIsDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

Color get kDark         => gIsDarkMode ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
Color get kDark2        => gIsDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF2C2C2C);
Color get kText         => gIsDarkMode ? const Color(0xFFCCCCCC) : const Color(0xFF3D3D3D);
Color get kMuted        => gIsDarkMode ? const Color(0xFF999999) : const Color(0xFF7A7A7A);
Color get kMuted2       => gIsDarkMode ? const Color(0xFF777777) : const Color(0xFFADADAD);

Color get kBorder       => gIsDarkMode ? const Color(0xFF333333) : const Color(0xFFE8E0D8);
Color get kBorder2      => gIsDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE5);

// ── BASE URL ─────────────────────────────────────────────────
// Konfigurasi menggunakan URL server Laravel yang sudah di-deploy.
String get kBaseUrl => 'http://senindrai.my.id';
String get kApiUrl  => 'http://senindrai.my.id/api/v1';

String getImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '$kApiUrl/file/$path';
}

// ── RADIUS ───────────────────────────────────────────────────
const kRadiusXs = 8.0;
const kRadiusSm = 12.0;
const kRadius   = 16.0;
const kRadiusLg = 20.0;
const kRadiusXl = 28.0;
const kRadiusFull = 999.0;

// ── SPACING ──────────────────────────────────────────────────
const kSpaceXs = 4.0;
const kSpaceSm = 8.0;
const kSpace   = 16.0;
const kSpaceMd = 20.0;
const kSpaceLg = 28.0;
const kSpaceXl = 40.0;

// ── THEME ────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary:   kPrimary,
      surface:   kBgCard,
    ),
    scaffoldBackgroundColor: kBgSoft,

    appBarTheme: AppBarTheme(
      backgroundColor:        kBgCard,
      elevation:              0,
      scrolledUnderElevation: 0.5,
      shadowColor:            kBorder,
      iconTheme:              IconThemeData(color: kDark, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation:       0,
        padding:         const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusFull)),
        textStyle: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: const Color(0xFFF5F3F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide:   BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide:   BorderSide(color: kBorder2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide:   BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide:   BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle:     TextStyle(color: kMuted, fontSize: 14),
      hintStyle:      TextStyle(color: kMuted2, fontSize: 14),
    ),
  );
}

// ── TEXT STYLES ──────────────────────────────────────────────
class AppText {
  // Display — Playfair
  static TextStyle get displayXl => TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 40, fontWeight: FontWeight.w900,
    color: kDark, letterSpacing: -1, height: 1.1,
  );
  static TextStyle get displayLg => TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 32, fontWeight: FontWeight.w900,
    color: kDark, letterSpacing: -0.8, height: 1.15,
  );
  static TextStyle get displayMd => TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 24, fontWeight: FontWeight.w800,
    color: kDark, letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle get displaySm => TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 20, fontWeight: FontWeight.w700,
    color: kDark, letterSpacing: -0.3, height: 1.25,
  );
  static TextStyle get displayXs => TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 17, fontWeight: FontWeight.w700,
    color: kDark, height: 1.3,
  );

  // Body
  static TextStyle get bodyLg    => TextStyle(fontSize: 16, color: kText, height: 1.7);
  static TextStyle get bodyMd    => TextStyle(fontSize: 14, color: kText, height: 1.65);
  static TextStyle get bodySm    => TextStyle(fontSize: 12, color: kMuted, height: 1.6);
  static TextStyle get bodyXs    => TextStyle(fontSize: 11, color: kMuted, height: 1.5);
  static TextStyle get label     => TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark, letterSpacing: 0.1);
  static TextStyle get labelSm   => TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.5);
  static TextStyle get caption   => TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kMuted, letterSpacing: 0.8);
}