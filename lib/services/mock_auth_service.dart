import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../utils/phone.dart';
import 'auth_models.dart';
import 'auth_service.dart';

/// Geliştirme ve saha testi için sahte doğrulama servisi.
///
/// Davranış:
/// * Herhangi bir telefon numarası veya e-posta kabul edilir.
/// * SMS/e-posta gönderilmez; üretilen kod ekranda ve konsolda gösterilir.
/// * Doğrulamada **herhangi bir 6 haneli kod** kabul edilir; böylece test
///   sırasında kod beklemeye gerek kalmaz.
///
/// Gerçek API devreye girdiğinde bu sınıf yalnızca birim testlerinde kullanılır.
class MockAuthService implements AuthService {
  MockAuthService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final Map<String, _MockRequest> _requests = <String, _MockRequest>{};

  static const Duration _latency = Duration(milliseconds: 600);
  static const int codeLength = 6;

  @override
  Future<OtpRequestResult> requestOtp({
    required OtpChannel channel,
    required String target,
  }) async {
    await Future<void>.delayed(_latency);

    if (target.trim().isEmpty) {
      throw const AuthException(
        AuthErrorCode.invalidTarget,
        'Lütfen telefon numarası veya e-posta giriniz.',
      );
    }

    final String code = List<int>.generate(codeLength, (_) => _random.nextInt(10)).join();
    final String requestId = 'mock-${DateTime.now().microsecondsSinceEpoch}';
    _requests[requestId] = _MockRequest(channel: channel, target: target, code: code);

    debugPrint('[MockAuth] $channel → $target : Giriş İçin Doğrulama Kodunuz : $code');

    return OtpRequestResult(
      requestId: requestId,
      expiresIn: 180,
      resendAfter: 60,
      maskedTarget:
          channel == OtpChannel.email ? maskEmail(target) : maskPhone(target),
      devCode: code,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String requestId,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);

    if (code.length != codeLength) {
      throw const AuthException(
        AuthErrorCode.invalidCode,
        'Doğrulama kodu 6 haneli olmalıdır.',
      );
    }

    // Test kolaylığı için kod içeriği kontrol edilmez; 6 hane yeterlidir.
    final _MockRequest? request = _requests.remove(requestId);
    final UserProfile base = MockData.user;

    return AuthSession(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      user: UserProfile(
        fullName: base.fullName,
        email: request?.channel == OtpChannel.email
            ? request!.target
            : base.email,
        phone: request != null && request.channel == OtpChannel.sms
            ? request.target
            : base.phone,
        role: base.role,
        registryNo: base.registryNo,
        machineCode: base.machineCode,
        machineType: base.machineType,
      ),
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    await Future<void>.delayed(_latency);
    return AuthSession(
      accessToken: 'mock-access-token',
      refreshToken: refreshToken,
      user: MockData.user,
    );
  }
}

class _MockRequest {
  _MockRequest({required this.channel, required this.target, required this.code});

  final OtpChannel channel;
  final String target;
  final String code;
}
