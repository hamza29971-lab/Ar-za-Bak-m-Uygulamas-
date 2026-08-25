import re
import os

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\otp_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix constructor
content = re.sub(
    r'const OtpScreen\(\{.*?\}\);',
    r'const OtpScreen({super.key, required this.phoneNumber, required this.correctCode, this.otpRequestId, this.password});',
    content,
    flags=re.DOTALL
)

# Fix OutlinedButton
pattern_btn = re.compile(r'OutlinedButton\(\s*onPressed:\s*_remainingSeconds == 0\s*\?\s*\(\)\s*\{\s*_startTimer\(\);\s*\}\s*:\s*null,', re.DOTALL)
replacement_btn = """OutlinedButton(
                            onPressed: _remainingSeconds == 0 && !_isResending
                                ? () async {
                                    if (AuthApiService.useRealApi && widget.password != null) {
                                      setState(() => _isResending = true);
                                      try {
                                        final newId = await AuthApiService.loginWithPhone(widget.phoneNumber, widget.password!);
                                        if (newId != null) {
                                          _currentOtpRequestId = newId;
                                          _startTimer();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Yeni doğrulama kodu gönderildi.')),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          String errorMsg = e.toString();
                                          if (errorMsg.startsWith('Exception: ')) errorMsg = errorMsg.substring(11);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
                                        }
                                      } finally {
                                        if (mounted) setState(() => _isResending = false);
                                      }
                                    } else {
                                      _startTimer();
                                    }
                                  }
                                : null,"""

if pattern_btn.search(content):
    content = pattern_btn.sub(replacement_btn, content)
    print("Button fixed")
else:
    print("Button NOT found")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
