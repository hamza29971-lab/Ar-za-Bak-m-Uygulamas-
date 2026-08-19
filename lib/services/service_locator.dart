import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_auth_service.dart';
import 'mock_auth_service.dart';
import 'token_storage.dart';

/// Uygulamanın servis bağımlılıklarını tek yerden verir.
///
/// Sahte/gerçek servis seçimi burada yapılır; ekranlar yalnızca arayüzleri
/// tanıdığı için geçiş tek satırlık bir değişikliktir.
class ServiceLocator {
  ServiceLocator._();

  static AuthService? _authService;
  static TokenStorage? _tokenStorage;

  static AuthService get auth => _authService ??=
      AppConfig.useMockAuth ? MockAuthService() : HttpAuthService();

  static TokenStorage get tokens => _tokenStorage ??= InMemoryTokenStorage();

  /// Testlerde sahte uygulamaları yerleştirmek için.
  static void override({AuthService? auth, TokenStorage? tokens}) {
    if (auth != null) _authService = auth;
    if (tokens != null) _tokenStorage = tokens;
  }

  static void reset() {
    _authService = null;
    _tokenStorage = null;
  }
}
