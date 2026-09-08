import 'package:flutter/material.dart';

/// NIMO uygulamasının renk paleti.
/// Açık tema referans arayüzdeki sade, beyaz zeminli ve yeşil vurgulu stildir.
/// Koyu tema ise aynı kimliği koruyan, düşük parlaklıkta nötr gri-mavi
/// yüzeyler ve aydınlatılmış vurgu renkleri üzerine kuruludur.
class AppColors {
  AppColors._();

  /// Ana marka yeşili (butonlar, aktif durumlar).
  static const Color brand = Color(0xFF3F8A24);
  static const Color brandLight = Color(0xFF7CC242);
  static const Color brandSoft = Color(0xFFE8F5E1);

  /// Modül renkleri (açık tema).
  static const Color tire = Color(0xFF3F8A24); // Lastik Değişimi
  static const Color oil = Color(0xFFD98A0B); // Yağ Takviyesi
  static const Color form = Color(0xFF2F6FED); // Servis Raporu
  static const Color mechanic = Color(0xFF6D3FBF); // Mekanik Operasyon
  static const Color emergency = Color(0xFFD64545);
  static const Color stop = Color(0xFF7B2D9E);
  static const Color fault = Color(0xFFF26522);

  // Açık tema yüzeyleri
  static const Color lightBg = Color(0xFFFFFFFF);

  /// Sayfa içeriğinin zemini. Üst bar ve alt sekme çubuğu beyaz kalır; asıl
  /// içerik alanı hafif gri olur, böylece tablolar ve paneller beyaz kart
  /// gibi öne çıkar.
  static const Color lightContent = Color(0xFFECEEF1);
  static const Color lightSurface = Color(0xFFF5F6F7);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6E8EA);
  static const Color lightText = Color(0xFF1C1F23);
  static const Color lightMuted = Color(0xFF6B7280);

  // ---------------------------------------------------------------- koyu tema
  /// Sayfa zemini. Tam siyah yerine hafif mavi-gri nötr; uzun süreli
  /// kullanımda göz yormaz ve yüzey katmanları ayırt edilebilir kalır.
  static const Color darkBg = Color(0xFF0F1216);

  /// Kart / girdi zemini (zeminin bir kademe üstü). Tablo, araç görseli ve
  /// form alanları bu renktedir; zeminden açık seçik ayrışsın diye sayfa
  /// zemininin belirgin biçimde üstünde tutulur.
  static const Color darkSurface = Color(0xFF1E262E);

  /// Diyalog, menü, tablo başlığı gibi bir kademe daha yüksek yüzeyler.
  static const Color darkElevated = Color(0xFF2A333D);

  /// Yüzey sınırları; koyu temada kart kenarının seçilebilmesi için
  /// yüzeyden bir kademe daha açıktır.
  static const Color darkBorder = Color(0xFF3D4A57);
  static const Color darkText = Color(0xFFE7ECF1);
  static const Color darkMuted = Color(0xFF97A3AE);

  /// Koyu zeminde marka yeşilinin okunabilir tonu.
  static const Color brandDark = Color(0xFF86CE4E);

  /// Koyu zeminde brandSoft karşılığı (yeşile çalan koyu dolgu).
  static const Color brandSoftDark = Color(0xFF1D2A18);

  /// Koyu zeminde okunabilir modül renkleri.
  static const Color tireDark = Color(0xFF86CE4E);
  static const Color oilDark = Color(0xFFEFB33F);
  static const Color formDark = Color(0xFF6BA5F7);
  static const Color mechanicDark = Color(0xFFAB8CF2);
  static const Color emergencyDark = Color(0xFFF07370);
  static const Color stopDark = Color(0xFFC482E8);
  static const Color faultDark = Color(0xFFFF8B4D);

  /// Açık tema için tanımlanmış bir vurgu rengini koyu temadaki karşılığına
  /// çevirir. Eşleşme yoksa renk bir miktar aydınlatılır ki koyu zeminde
  /// boğulmasın.
  static Color onDark(Color color) {
    switch (color.toARGB32()) {
      case 0xFF3F8A24: // brand / tire
        return brandDark;
      case 0xFF7CC242: // brandLight
        return brandLight;
      case 0xFFD98A0B: // oil
        return oilDark;
      case 0xFF2F6FED: // form
        return formDark;
      case 0xFF6D3FBF: // mechanic
        return mechanicDark;
      case 0xFFD64545: // emergency
        return emergencyDark;
      case 0xFF7B2D9E: // stop
        return stopDark;
      case 0xFFF26522: // fault
        return faultDark;
      case 0xFFE8F5E1: // brandSoft
        return brandSoftDark;
      case 0xFF2B3252: // lastik ekranındaki lacivert vurgu
        return const Color(0xFF9AA8D4);
      case 0xFF198754: // onay yeşili
        return const Color(0xFF4ADE80);
      case 0xFF2B5CE6: // bilgi mavisi
        return const Color(0xFF7FA6FF);
      case 0xFFF59E0B: // uyarı sarısı
        return const Color(0xFFFBBF3C);
    }
    final HSLColor hsl = HSLColor.fromColor(color);
    if (hsl.lightness >= 0.62) return color;
    return hsl.withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0)).toColor();
  }
}

/// Tema içinden kolay erişim için yüzey/çizgi renkleri.
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Sayfa zemini üzerindeki kartların rengi.
  Color get cardColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;

  /// Diyalog / menü gibi bir kademe daha yüksek yüzeyler.
  Color get elevatedColor =>
      isDark ? AppColors.darkElevated : AppColors.lightElevated;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.lightBorder;

  /// Normal kenarlıktan daha belirgin ayırıcı çizgi. Alt sekme çubuğundaki
  /// dikey ayraçlar gibi, sekmelerin birbirinden net ayrılması gereken
  /// yerlerde kullanılır.
  Color get strongBorderColor =>
      isDark ? const Color(0xFF6B7A86) : const Color(0xFF9AA1A9);
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get pageColor => isDark ? AppColors.darkBg : AppColors.lightBg;

  /// Üst bar ile alt sekme çubuğu arasında kalan içerik alanının zemini.
  /// Açık temada hafif gri; kartlar, tablolar ve paneller bunun üzerinde
  /// beyaz kalarak ayrışır.
  Color get contentColor => isDark ? AppColors.darkBg : AppColors.lightContent;

  /// Marka yeşilinin aktif temadaki okunabilir tonu.
  Color get brandColor => isDark ? AppColors.brandDark : AppColors.brand;

  /// Marka yeşilinin soluk dolgu tonu (rozet, avatar zemini).
  Color get brandSoftColor =>
      isDark ? AppColors.brandSoftDark : AppColors.brandSoft;

  /// Bir vurgu rengini aktif temaya uyarlar.
  Color accent(Color color) => isDark ? AppColors.onDark(color) : color;

  /// Dolgulu (beyaz yazılı) butonlar için vurgu rengi. Koyu temada renk
  /// hafif açılır ama beyaz yazının okunurluğunu bozacak kadar değil.
  Color accentFill(Color color) {
    if (!isDark) return color;
    final HSLColor hsl = HSLColor.fromColor(color);
    if (hsl.lightness >= 0.42) return color;
    return hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 0.46)).toColor();
  }

  /// Vurgu renginin soluk dolgu tonu (rozet, seçili sekme zemini).
  Color accentSoft(Color color, {double light = 0.10, double dark = 0.18}) =>
      accent(color).withValues(alpha: isDark ? dark : light);

  // ------------------------------------------------- giriş / OTP ekranları
  // Bu ekranlar tasarım gereği kendi sabit renk paletini kullanıyordu;
  // aşağıdaki karşılıklar sayesinde koyu temada da doğru görünüyorlar.
  Color get authBg => isDark ? AppColors.darkBg : Colors.white;
  Color get authField => isDark ? AppColors.darkSurface : Colors.white;
  Color get authSoft =>
      isDark ? AppColors.darkSurface : const Color(0xFFF2F4F8);
  Color get authPanel =>
      isDark ? AppColors.darkSurface : const Color(0xFFF8F9FC);
  Color get authTitle => isDark ? AppColors.darkText : const Color(0xFF1A1D2E);
  Color get authMuted => isDark ? AppColors.darkMuted : const Color(0xFF7B8094);
  Color get authHint =>
      isDark ? const Color(0xFF6C7883) : const Color(0xFFBBC0CC);
  Color get authBorder =>
      isDark ? AppColors.darkBorder : const Color(0xFFDDE1EA);
  Color get authDivider =>
      isDark ? AppColors.darkBorder : const Color(0xFFEEF0F5);

  /// Yazı / çerçeve için yeşil.
  Color get authGreen =>
      isDark ? AppColors.brandDark : const Color(0xFF2E7D32);

  /// Beyaz yazılı dolgular için yeşil.
  Color get authGreenFill =>
      isDark ? const Color(0xFF4E9E2C) : const Color(0xFF2E7D32);
  Color get authGreenSoft =>
      isDark ? AppColors.brandSoftDark : const Color(0xFFE8F5E9);
  Color get authError =>
      isDark ? AppColors.emergencyDark : const Color(0xFFD32F2F);

  /// Araç fotoğraflarının zemini. Görseller şeffaf arka planlı olduğu için
  /// koyu temada kart tonu bile yetmiyor; aracın koyu bölgeleri zemine
  /// karışıyor. Bu yüzden fotoğraf tablası kartlardan bir kademe daha açık.
  Color get photoPlate =>
      isDark ? const Color(0xFF262E37) : AppColors.lightBg;

  /// Bilgi kutularının soluk mavi zemini.
  Color get infoSoft =>
      isDark ? const Color(0xFF17202E) : const Color(0xFFF0F4FF);

  /// Kaydetme animasyonunda kısa süre yanıp sönen yeşil zemin.
  Color get successFlash =>
      isDark ? const Color(0xFF1E3324) : const Color(0xFFD4EDDA);

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
    final Color elevated =
        dark ? AppColors.darkElevated : AppColors.lightElevated;
    final Color border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textColor = dark ? AppColors.darkText : AppColors.lightText;
    final Color muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final Color primary = dark ? AppColors.brandDark : AppColors.brand;

    // Dolgulu butonlar iki temada da beyaz yazılı yeşil kalsın; koyu temada
    // zeminden ayrışması için yeşil bir tık açılır.
    final Color filledBg = dark ? const Color(0xFF4E9E2C) : AppColors.brand;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? const Color(0xFF0C1409) : Colors.white,
      secondary: primary,
      surface: bg,
      onSurface: textColor,
      surfaceContainerHighest: elevated,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      error: dark ? AppColors.emergencyDark : AppColors.emergency,
    );

    final Typography typography =
        Typography.material2021(platform: TargetPlatform.android);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      // M3'ün yüzey tonlaması koyu temada her yüzeyi yeşile çalıyor; kapatıldı.
      applyElevationOverlayColor: false,
      iconTheme: IconThemeData(color: textColor),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      textTheme: (dark ? typography.white : typography.black)
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
      // Açılır menüler (ör. rapor türü) yüzey renginde olsun; M3'ün yüzey
      // tonlaması menüyü yeşile çalar.
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(elevated),
          surfaceTintColor:
              const WidgetStatePropertyAll<Color>(Colors.transparent),
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
        color: elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
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
        labelStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
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
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.30),
        selectionHandleColor: primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: filledBg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: muted.withValues(alpha: dark ? 0.22 : 0.30),
          disabledForegroundColor: muted,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
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
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
        side: BorderSide(color: muted, width: 1.4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? Colors.white : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? primary : border,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkElevated : const Color(0xFF23282D),
          borderRadius: BorderRadius.circular(8),
          border: dark ? Border.all(color: border) : null,
        ),
        textStyle: TextStyle(
          color: dark ? textColor : Colors.white,
          fontSize: 12,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          muted.withValues(alpha: dark ? 0.35 : 0.30),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.darkElevated : const Color(0xFF23282D),
        contentTextStyle: TextStyle(color: dark ? textColor : Colors.white),
        actionTextColor: dark ? AppColors.brandDark : AppColors.brandLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        // Koyu temada diyalog, arkasındaki karartmadan ayrışsın diye sayfa
        // zemininden bir kademe yukarıda durur.
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: dark ? 6 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: dark ? BorderSide(color: border) : BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: textColor,
      ),
    );
  }
}
