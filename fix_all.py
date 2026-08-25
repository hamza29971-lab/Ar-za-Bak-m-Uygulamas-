import re
import os

files = {
    r'C:\new class\nimo_ariza_bakim\lib\ui\screens\otp_screen.dart': [
        (
            "payload['user'] ?? payload['profile'] ?? payload",
            "payload['userData'] ?? payload['user'] ?? payload['profile'] ?? payload"
        )
    ],
    r'C:\new class\nimo_ariza_bakim\lib\models\models.dart': [
        (
            "role: json['role'] as String? ?? json['title'] as String? ?? '',",
            "role: (json['role'] is Map ? json['role']['name'] as String? : json['role'] as String?) ?? json['title'] as String? ?? '',"
        ),
        (
            "email: json['email'] as String? ?? '',",
            "email: json['email'] as String? ?? json['mail'] as String? ?? '',"
        )
    ],
    r'C:\new class\nimo_ariza_bakim\lib\ui\screens\login_screen.dart': [
        (
            """if (AuthApiService.useRealApi) {
      // Gerçek API ile Login
      // Yükleniyor dialogu gösterilebilir (basitlik için bekleme süresince UI bloklanmıyor)
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarısız. Bilgilerinizi kontrol ediniz.')),
        );
      }
      return;
    }""",
            """if (AuthApiService.useRealApi) {
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
        )
    ]
}

for file_path, replacements in files.items():
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        continue
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
        else:
            print(f"Pattern not found in {os.path.basename(file_path)}: {old[:50]}...")
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {os.path.basename(file_path)}")

