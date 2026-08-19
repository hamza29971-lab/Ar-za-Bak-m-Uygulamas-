/// Ortam ayarları.
///
/// Değerler `--dart-define` ile derleme sırasında verilebilir; verilmezse
/// geliştirme varsayılanları kullanılır:
///
/// ```bash
/// flutter run -d windows --dart-define=NIMO_USE_MOCK_AUTH=false --dart-define=NIMO_API_BASE_URL=https://nimo-api.nuhcimento.com.tr
/// ```
class AppConfig {
  AppConfig._();

  /// `true` iken giriş akışı sahte servisle çalışır: herhangi bir telefon
  /// numarası ve herhangi bir 6 haneli kod kabul edilir, SMS gönderilmez.
  /// Gerçek NIMO API hazır olduğunda `false` verilir.
  static const bool useMockAuth =
      bool.fromEnvironment('NIMO_USE_MOCK_AUTH', defaultValue: true);

  /// NIMO API adresi (gerçek mod).
  static const String apiBaseUrl = String.fromEnvironment(
    'NIMO_API_BASE_URL',
    defaultValue: 'https://nimo-api.nuhcimento.com.tr',
  );

  /// Ağ isteklerinde zaman aşımı. Saha tabletlerinde bağlantı zayıf olabilir.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Sahte modda üretilen doğrulama kodu ekranda gösterilsin mi?
  static const bool showMockCode = useMockAuth;
}
