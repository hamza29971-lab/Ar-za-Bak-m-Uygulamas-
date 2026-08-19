import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  // Feature flag: Gerçek API'ye bağlanmak için true yapın
  static const bool useRealApi = true;
  
  static const String baseUrl = 'https://mining-be.ndmo.com.tr';

  /// Login isteği atar, başarılıysa otpRequestId döner.
  static Future<String?> loginWithPhone(String emailOrPhoneNumber, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhoneNumber': emailOrPhoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // API'nin döndüğü otpRequestId alanını alıyoruz
        return data['otpRequestId']?.toString();
      } else {
        print('Login Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login Exception: $e');
      return null;
    }
  }

  /// Gelen OTP kodunu doğrular, başarılıysa profil bilgilerini (varsa) döner.
  static Future<Map<String, dynamic>?> verifyOtp(String otpRequestId, String phoneNumber, String otp) async {
    final url = Uri.parse('$baseUrl/auth/login/otp/verify');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'otpRequestId': otpRequestId,
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data; // Genelde token ve user nesnesini döner
      } else {
        print('Verify OTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Verify OTP Exception: $e');
      return null;
    }
  }
}
