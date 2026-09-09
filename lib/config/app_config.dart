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

  /// Nimo Fleet API adresi.
  static const String fleetEventUrl = String.fromEnvironment(
    'NIMO_FLEET_URL',
    defaultValue: 'https://nimo-fleet-panel.vercel.app/api/event',
  );

  /// Görsellerin yüklendiği uç nokta. Rapor gönderimi iki aşamalıdır:
  /// önce her görsel buraya multipart olarak yüklenir, dönen URL'ler
  /// ardından [fleetEventUrl]'e JSON olarak gider.
  static const String fleetUploadUrl = String.fromEnvironment(
    'NIMO_FLEET_UPLOAD_URL',
    defaultValue: 'https://nimo-fleet-panel.vercel.app/api/upload',
  );

  /// Yüklemede multipart gövdenin alan adı.
  static const String fleetUploadField = String.fromEnvironment(
    'NIMO_FLEET_UPLOAD_FIELD',
    defaultValue: 'file',
  );

  /// Görsel yüklemesi için ayrı zaman aşımı. Saha bağlantısında bir
  /// fotoğraf [requestTimeout] içinde bitmeyebilir.
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// Nimo Fleet Health URL.
  static const String fleetHealthUrl = String.fromEnvironment(
    'NIMO_FLEET_HEALTH_URL',
    defaultValue: 'https://nimo-fleet-panel.vercel.app/api/health',
  );

  /// Nimo Fleet API anahtarı.
  static const String fleetApiKey = String.fromEnvironment(
    'NIMO_FLEET_KEY',
    defaultValue: 'nimo-fleet-test-tablet-key',
  );

  /// Nimo Fleet Source.
  static const String fleetSource = String.fromEnvironment(
    'NIMO_FLEET_SOURCE',
    defaultValue: 'tablet',
  );
}
