import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\services\auth_api_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // API'nin döndüğü veri yapısı: data['data']['otpRequestId']
        return data['data']?['otpRequestId']?.toString();
      } else {
        print('Login Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login Exception: $e');
      return null;
    }"""

replacement = """      if (response.statusCode == 200 || response.statusCode == 201) {
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
    }"""

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('AuthApiService Success')
else:
    print('AuthApiService Target not found')
