import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Doğrulama kodunun gönderileceği kanal.
enum OtpChannel { sms, email }

/// `POST /auth/otp/request` yanıtı.
@immutable
class OtpRequestResult {
  const OtpRequestResult({
    required this.requestId,
    required this.expiresIn,
    required this.resendAfter,
    required this.maskedTarget,
    this.devCode,
  });

  /// Doğrulama isteğinin kimliği; `verify` çağrısında geri gönderilir.
  final String requestId;

  /// Kodun geçerlilik süresi (saniye).
  final int expiresIn;

  /// Yeniden gönderim için beklenmesi gereken süre (saniye).
  final int resendAfter;

  /// Ekranda gösterilecek maskelenmiş hedef, ör. `******* *062`.
  final String maskedTarget;

  /// Yalnızca sahte modda dolu olur: üretilen kod ekranda gösterilir.
  /// Gerçek API bu alanı asla döndürmez.
  final String? devCode;

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) => OtpRequestResult(
        requestId: json['requestId'] as String,
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 180,
        resendAfter: (json['resendAfter'] as num?)?.toInt() ?? 60,
        maskedTarget: json['maskedTarget'] as String? ?? '',
      );
}

/// `POST /auth/otp/verify` yanıtı.
@immutable
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserProfile user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Arayüzde farklı mesaj gösterilmesi gereken hata türleri.
enum AuthErrorCode {
  /// Numara/e-posta biçimi geçersiz.
  invalidTarget,

  /// Çok fazla kod isteği yapıldı.
  rateLimited,

  /// Girilen kod yanlış.
  invalidCode,

  /// Kodun süresi doldu.
  expired,

  /// Deneme hakkı bitti.
  tooManyAttempts,

  /// Bağlantı kurulamadı / zaman aşımı.
  network,

  /// Sunucu veya operatör kaynaklı hata.
  server,
}

class AuthException implements Exception {
  const AuthException(this.code, this.message, {this.retryAfter, this.remainingAttempts});

  final AuthErrorCode code;
  final String message;

  /// `rateLimited` durumunda kaç saniye sonra tekrar denenebileceği.
  final int? retryAfter;

  /// `invalidCode` durumunda kalan deneme hakkı.
  final int? remainingAttempts;

  /// Sunucudan gelen hata kodunu [AuthErrorCode] karşılığına çevirir.
  factory AuthException.fromServer(String? code, Map<String, dynamic> body) {
    final int? retryAfter = (body['retryAfter'] as num?)?.toInt();
    final int? remaining = (body['remainingAttempts'] as num?)?.toInt();
    return switch (code) {
      'RATE_LIMITED' => AuthException(
          AuthErrorCode.rateLimited,
          'Çok fazla deneme yaptınız. ${retryAfter ?? 60} saniye sonra tekrar deneyin.',
          retryAfter: retryAfter,
        ),
      'INVALID_CODE' => AuthException(
          AuthErrorCode.invalidCode,
          remaining == null
              ? 'Doğrulama kodu hatalı.'
              : 'Doğrulama kodu hatalı. Kalan hakkınız: $remaining',
          remainingAttempts: remaining,
        ),
      'EXPIRED' => const AuthException(
          AuthErrorCode.expired,
          'Kodun süresi doldu. Yeni kod isteyin.',
        ),
      'TOO_MANY_ATTEMPTS' => const AuthException(
          AuthErrorCode.tooManyAttempts,
          'Deneme hakkınız bitti. Yeni kod isteyin.',
        ),
      'INVALID_TARGET' => const AuthException(
          AuthErrorCode.invalidTarget,
          'Girilen bilgi geçersiz. Lütfen kontrol edin.',
        ),
      _ => const AuthException(
          AuthErrorCode.server,
          'İşlem tamamlanamadı. Lütfen daha sonra tekrar deneyin.',
        ),
    };
  }

  @override
  String toString() => 'AuthException($code): $message';
}
