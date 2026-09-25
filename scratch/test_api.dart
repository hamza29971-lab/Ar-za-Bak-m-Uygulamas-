import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://mining-be.ndmo.com.tr/services/public/search-autocomplete-filter');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "pageNumber": 0,
      "pageSize": 20,
      "filters": []
    }),
  );
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
