import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/phone.dart';
import 'auth_models.dart';
import 'auth_service.dart';

/// Gerçek NIMO API'sine bağlanan doğrulama servisi.
///
/// Beklenen uç noktalar (bkz. `docs/otp-sms-plan.md`):
/// * `POST /auth/otp/request` → `{ requestId, expiresIn, resendAfter, maskedTarget }`
/// * `POST /auth/otp/verify`  → `{ accessToken, refreshToken, user }`
/// * `POST /auth/refresh`     → `{ accessToken, refreshToken, user }`
///
/// Hata gövdesi: `{ "error": "RATE_LIMITED", "retryAfter": 42 }`
class HttpAuthService implements AuthService {
  HttpAuthService({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<OtpRequestResult> requestOtp({
    required OtpChannel channel,
    required String target,
  }) async {
    final Map<String, dynamic> body = await _post('/auth/otp/request', <String, dynamic>{
      if (channel == OtpChannel.sms) 'phone': normalizePhone(target) else 'email': target.trim(),
      'channel': channel.name,
    });
    return OtpRequestResult.fromJson(body);
  }

  @override
  Future<AuthSession> verifyOtp({
    required String requestId,
    required String code,
  }) async {
    final Map<String, dynamic> body = await _post('/auth/otp/verify', <String, dynamic>{
      'requestId': requestId,
      'code': code,
    });
    return AuthSession.fromJson(body);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final Map<String, dynamic> body = await _post('/auth/refresh', <String, dynamic>{
      'refreshToken': refreshToken,
    });
    return AuthSession.fromJson(body);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse('$_baseUrl$path');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const AuthException(
        AuthErrorCode.network,
        'Sunucuya ulaşılamadı. Lütfen tekrar deneyin.',
      );
    } on SocketException {
      throw const AuthException(
        AuthErrorCode.network,
        'Bağlantı kurulamadı. İnternet bağlantınızı kontrol edin.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthErrorCode.network,
        'Bağlantı kurulamadı. İnternet bağlantınızı kontrol edin.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } on FormatException {
        body = <String, dynamic>{};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    throw AuthException.fromServer(body['error'] as String?, body);
  }

  void dispose() => _client.close();
}
