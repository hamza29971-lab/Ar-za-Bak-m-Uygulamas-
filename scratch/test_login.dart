import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'https://mining-be.ndmo.com.tr';
  const String phone = '05443760910';
  const String password = 'nimo09100U';
  
  final url = Uri.parse('$baseUrl/auth/login');
  try {
    final String base64Password = base64Encode(utf8.encode(password));
    
    print('Sending login request for $phone...');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailOrPhoneNumber': phone,
        'password': base64Password,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final otpRequestId = data['data']?['otpRequestId']?.toString();
      print('=== SUCCESS ===');
      print('OTP Request ID: $otpRequestId');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
