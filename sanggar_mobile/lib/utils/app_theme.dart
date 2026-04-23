// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── WARNA ────────────────────────────────────────────────────
const kPrimary      = Color(0xFFC65D2E);
const kPrimaryDark  = Color(0xFFA34A22);
const kPrimaryLight = Color(0xFFE07A4F);
const kPrimaryPale  = Color(0xFFFDF0EA);
const kPrimaryPale2 = Color(0xFFF9E4D6);
const kDark         = Color(0xFF1A1A1A);
const kDark2        = Color(0xFF2C2C2C);
const kText         = Color(0xFF3D3D3D);
const kMuted        = Color(0xFF7A7A7A);
const kMuted2       = Color(0xFFADADAD);
const kBorder       = Color(0xFFE8E0D8);
const kBorder2      = Color(0xFFF0EBE5);
const kBgSoft       = Color(0xFFFAF8F6);
const kBgCard       = Color(0xFFFFFFFF);
const kGold         = Color(0xFFD4AF37);

// ── BASE URL ─────────────────────────────────────────────────
// Emulator Android: http://10.0.2.2:8000
// Device fisik    : http://IP-WIFI-PC:8000
const kBaseUrl = 'http://10.0.2.2:8000';
const kApiUrl  = "http://127.0.0.1:8000/api/v1";

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

    appBarTheme: const AppBarTheme(
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
        textStyle: const TextStyle(
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
        borderSide:   const BorderSide(color: kBorder2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide:   const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide:   const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle:     const TextStyle(color: kMuted, fontSize: 14),
      hintStyle:      const TextStyle(color: kMuted2, fontSize: 14),
    ),
  );
}

// ── TEXT STYLES ──────────────────────────────────────────────
class AppText {
  // Display — Playfair
  static const displayXl = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 40, fontWeight: FontWeight.w900,
    color: kDark, letterSpacing: -1, height: 1.1,
  );
  static const displayLg = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 32, fontWeight: FontWeight.w900,
    color: kDark, letterSpacing: -0.8, height: 1.15,
  );
  static const displayMd = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 24, fontWeight: FontWeight.w800,
    color: kDark, letterSpacing: -0.5, height: 1.2,
  );
  static const displaySm = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 20, fontWeight: FontWeight.w700,
    color: kDark, letterSpacing: -0.3, height: 1.25,
  );
  static const displayXs = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 17, fontWeight: FontWeight.w700,
    color: kDark, height: 1.3,
  );

  // Body
  static const bodyLg    = TextStyle(fontSize: 16, color: kText, height: 1.7);
  static const bodyMd    = TextStyle(fontSize: 14, color: kText, height: 1.65);
  static const bodySm    = TextStyle(fontSize: 12, color: kMuted, height: 1.6);
  static const bodyXs    = TextStyle(fontSize: 11, color: kMuted, height: 1.5);
  static const label     = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark, letterSpacing: 0.1);
  static const labelSm   = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.5);
  static const caption   = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kMuted, letterSpacing: 0.8);
}