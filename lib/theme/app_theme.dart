import 'package:flutter/material.dart';

/// NIMO uygulamasının renk paleti.
/// Referans arayüzdeki sade, açık zeminli ve yeşil vurgulu stil esas alınmıştır.
class AppColors {
  AppColors._();

  /// Ana marka yeşili (butonlar, aktif durumlar).
  static const Color brand = Color(0xFF3F8A24);
  static const Color brandLight = Color(0xFF7CC242);
  static const Color brandSoft = Color(0xFFE8F5E1);

  /// Modül renkleri.
  static const Color tire = Color(0xFF3F8A24); // Lastik Değişimi
  static const Color oil = Color(0xFFD98A0B); // Yağ Takviyesi
  static const Color form = Color(0xFF2F6FED); // Servis Raporu
  static const Color emergency = Color(0xFFD64545);
  static const Color stop = Color(0xFF7B2D9E);
  static const Color fault = Color(0xFFF26522);

  // Açık tema yüzeyleri
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F6F7);
  static const Color lightBorder = Color(0xFFE6E8EA);
  static const Color lightText = Color(0xFF1C1F23);
  static const Color lightMuted = Color(0xFF6B7280);

  // Koyu tema yüzeyleri
  static const Color darkBg = Color(0xFF14171A);
  static const Color darkSurface = Color(0xFF1E2226);
  static const Color darkBorder = Color(0xFF2C3238);
  static const Color darkText = Color(0xFFF2F4F6);
  static const Color darkMuted = Color(0xFF9BA3AD);
}

/// Tema içinden kolay erişim için yüzey/çizgi renkleri.
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get pageColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  AppTheme._();

  static const double radius = 16;
  static const double pagePadding = 24;

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final Color bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final Color surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textColor = dark ? AppColors.darkText : AppColors.lightText;
    final Color muted = dark ? AppColors.darkMuted : AppColors.lightMuted;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(
      primary: dark ? AppColors.brandLight : AppColors.brand,
      surface: bg,
      onSurface: textColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(bodyColor: textColor, displayColor: textColor)
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            bodyMedium: TextStyle(fontSize: 14, color: textColor),
            bodySmall: TextStyle(fontSize: 12, color: muted),
          ),
      // Açılır menüler (ör. rapor türü) sayfa zeminiyle aynı renkte olsun;
      // M3'ün yüzey tonlaması menüyü yeşile çalar.
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(bg),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          elevation: const WidgetStatePropertyAll<double>(3),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(vertical: 6),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: border),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkSurface : Colors.white,
        hintStyle: TextStyle(color: muted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: border),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.darkSurface : const Color(0xFF23282D),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
