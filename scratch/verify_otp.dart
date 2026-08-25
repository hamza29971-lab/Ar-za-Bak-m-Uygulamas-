import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Lütfen OTP kodunu argüman olarak verin.');
    return;
  }
  
  final String otp = args[0];
  const String baseUrl = 'https://mining-be.ndmo.com.tr';
  const String phone = '05443760910';
  const String otpRequestId = '52d3ba65-c47f-4ec5-970d-703ed62c1ea2';
  
  final url = Uri.parse('$baseUrl/auth/login/otp/verify');
  try {
    print('Verifying OTP $otp for Request ID $otpRequestId...');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'otpRequestId': otpRequestId,
        'phoneNumber': phone,
        'otp': otp,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Raw Response Body:');
    print(response.body);
    
  } catch (e) {
    print('Exception: $e');
  }
}
