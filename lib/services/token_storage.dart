import 'auth_models.dart';

/// Oturum anahtarlarının saklanması.
///
/// Şu an bellekte tutulur; uygulama kapanınca oturum düşer. Gerçek API
/// devreye girdiğinde `flutter_secure_storage` tabanlı bir uygulama yazılıp
/// [ServiceLocator] içinde bununla değiştirilecek — ekranlarda değişiklik
/// gerekmez.
abstract interface class TokenStorage {
  Future<void> save(AuthSession session);
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clear();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> save(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
