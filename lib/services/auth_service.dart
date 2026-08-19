import 'auth_models.dart';

/// Giriş / doğrulama akışının sözleşmesi.
///
/// İki uygulaması vardır:
/// * [MockAuthService] — geliştirme ve saha testi; SMS göndermez.
/// * [HttpAuthService] — gerçek NIMO API'si.
///
/// Ekranlar yalnızca bu arayüzü tanır; gerçek servise geçiş
/// `AppConfig.useMockAuth` değerini `false` yapmakla olur.
abstract interface class AuthService {
  /// Hedefe (telefon veya e-posta) doğrulama kodu gönderilmesini ister.
  ///
  /// Hata durumunda [AuthException] fırlatır.
  Future<OtpRequestResult> requestOtp({
    required OtpChannel channel,
    required String target,
  });

  /// Kodu doğrular ve oturum bilgisini döndürür.
  ///
  /// Hata durumunda [AuthException] fırlatır.
  Future<AuthSession> verifyOtp({
    required String requestId,
    required String code,
  });

  /// Süresi dolan erişim anahtarını yeniler.
  Future<AuthSession> refresh(String refreshToken);
}
