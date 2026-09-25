import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final url = Uri.parse('https://api.github.com/repos/hamza29971-lab/Nimo_bak-m_g-ncelleme/contents/version.json?t=$ts');
  final headers = {
    'Authorization': 'Bearer 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',
    'Accept': 'application/vnd.github.raw+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  print('Fetching from $url');
  final response = await http.get(url, headers: headers);
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      print('Build Number: ${data['build_number']}');
    } catch (e) {
      print('JSON Error: $e');
    }
  }
}
