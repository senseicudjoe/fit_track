import 'package:flutter/material.dart';

// ── Colours ──────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const background     = Color(0xFF0E0E12);
  static const surface        = Color(0xFF13131A);
  static const card           = Color(0xFF1A1A24);
  static const cardAlt        = Color(0xFF1F1F2C);
  static const border         = Color(0xFF2A2A35);

  static const primary        = Color(0xFF7C6FF7); // purple
  static const primaryLight   = Color(0xFFAFA9EC);

  static const teal           = Color(0xFF4ECBA4);
  static const amber          = Color(0xFFF5A623);
  static const coral          = Color(0xFFF07B5E);
  static const red            = Color(0xFFE24B4A);

  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0x99FFFFFF); // 60%
  static const textHint       = Color(0x40FFFFFF); // 25%
}

// ── Typography ────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk',
  );
  static const heading2 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk',
  );
  static const heading3 = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
  static const label = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.textHint, letterSpacing: 0.6,
  );
  static const statValue = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk',
  );
}

// ── Spacing ───────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 24.0;
  static const xxl = 32.0;
}

// ── Border radius ─────────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const full = BorderRadius.all(Radius.circular(100));
}

// ── Theme ─────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.heading2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      labelStyle: AppTextStyles.caption,
      hintStyle: AppTextStyles.caption,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

// ── Asset paths ───────────────────────────────────────────────────────────────

class AppAudio {
  AppAudio._();

  static const motivationBeat  = 'assets/audio/motivation_beat.mp3';
  static const intervalBeep    = 'assets/audio/interval_beep.mp3';
  static const cooldownTrack   = 'assets/audio/cooldown_track.mp3';
  static const completionCheer = 'assets/audio/completion_cheer.mp3';

  static const List<String> playlist = [motivationBeat, cooldownTrack];
}