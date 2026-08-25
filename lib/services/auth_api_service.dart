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
      final String base64Password = base64Encode(utf8.encode(password));
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhoneNumber': emailOrPhoneNumber,
          'password': base64Password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // API'nin döndüğü veri yapısı: data['data']['otpRequestId']
        return data['data']?['otpRequestId']?.toString();
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Giriş başarısız. Bilgilerinizi kontrol ediniz.';
        throw Exception(message);
      }
    } catch (e) {
      print('Login Exception: $e');
      rethrow;
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
