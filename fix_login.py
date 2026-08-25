import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\login_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(
    r'if \(AuthApiService\.useRealApi\)\s*\{\s*// Gerçek API ile Login.*?final otpRequestId = await AuthApiService\.loginWithPhone\(loginId, password\);.*?if \(otpRequestId != null\) \{.*?Navigator\.of\(context\)\.pushReplacement\(.*?\}\s*else\s*\{.*?ScaffoldMessenger.*?\}\s*return;\s*\}',
    re.DOTALL | re.IGNORECASE
)

replacement = """if (AuthApiService.useRealApi) {
        // Gerçek API ile Login
        try {
          final otpRequestId = await AuthApiService.loginWithPhone(loginId, password);
          
          if (!mounted) return;
          
          if (otpRequestId != null) {
            // OTP Ekranına yönlendir
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    OtpScreen(phoneNumber: loginId, correctCode: '', otpRequestId: otpRequestId),
                transitionsBuilder: (context, anim, secondaryAnim, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          String errorMsg = e.toString();
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.substring(11);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
        return;
      }"""

if pattern.search(content):
    content = pattern.sub(replacement, content)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('LoginScreen Success')
else:
    print('LoginScreen Target not found')
