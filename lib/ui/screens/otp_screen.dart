import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/shell_screen.dart';
import 'login_screen.dart';
import '../../services/auth_api_service.dart';
import '../../services/auth_models.dart';
import '../../state/app_state.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String correctCode;
  final String? otpRequestId; // API isteğinden dönen ID
  
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.correctCode,
    this.otpRequestId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _enteredCode = '';
  int _remainingSeconds = 48;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _remainingSeconds = 48);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onNumKey(String key) {
    if (_enteredCode.length < 6) {
      setState(() {
        _enteredCode += key;
        _errorMessage = null;
      });
    }
  }

  void _onDelete() {
    if (_enteredCode.isNotEmpty) {
      setState(() {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredCode = '';
      _errorMessage = null;
    });
  }
  Future<void> _verifyCode() async {
    if (AuthApiService.useRealApi && widget.otpRequestId != null) {
      // Gerçek API Doğrulaması
      final data = await AuthApiService.verifyOtp(
        widget.otpRequestId!, 
        widget.phoneNumber, 
        _enteredCode,
      );
      
      if (!mounted) return;
      
      if (data != null) {
        // Profil bilgisini state'e kaydet (eğer API JSON'u AuthSession'a uyumluysa)
        try {
          final session = AuthSession.fromJson(data);
          AppScope.read(context).applySession(session);
        } catch (e) {
          debugPrint('AuthSession Parse Hatası: $e');
          // Dummy verilerle test login
          AppScope.read(context).signIn(phone: widget.phoneNumber);
        }
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ShellScreen(),
            transitionsBuilder: (context, anim, secondaryAnim, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Doğrulama kodu hatalı veya süresi dolmuş.';
        });
      }
      return;
    }

    // --- Eski Mantık ---
    if (_enteredCode == widget.correctCode) {
      // Eski test/dummy mantığıyla giriş yap
      AppScope.read(context).signIn(phone: widget.phoneNumber);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ShellScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Doğrulama kodu hatalı';
      });
    }
  }

  String get _maskedPhone {
    String cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length >= 10) {
      return '*******${cleanPhone.substring(cleanPhone.length - 3)}';
    }
    return widget.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Sol Panel: OTP Formu ────────────────────────────────
          SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlıklar
                    const Text(
                      'NIMO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D2E),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'NUH INTELLIGENT MINING OPERATIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B8094),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'İki Adımlı Doğrulama',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cep telefonunuza bir sms ile doğrulama kodu gönderildi. Aşağıdaki alana gelen kodu giriniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7B8094),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _maskedPhone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP Kutucukları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        bool isFilled = index < _enteredCode.length;
                        String char = isFilled ? _enteredCode[index] : '';
                        
                        return Container(
                          width: 48,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isFilled ? const Color(0xFF2E7D32) : const Color(0xFFDDE1EA),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFF8F9FC),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            char,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1D2E),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Tablet için hızlı tuş takımı',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B8094),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Özel Numpad
                    _NumPad(
                      onKey: _onNumKey,
                      onDelete: _onDelete,
                      onClear: _onClear,
                    ),

                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                    // Geri Sayım ve Tekrar Gönder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _remainingSeconds > 0
                              ? 'Kod 0:${_remainingSeconds.toString().padLeft(2, '0')} içinde geçerli'
                              : 'Kod süresi doldu',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7B8094),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _remainingSeconds == 0
                              ? () {
                                  _startTimer();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _remainingSeconds == 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFDDE1EA),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tekrar gönder${_remainingSeconds > 0 ? " (0:${_remainingSeconds.toString().padLeft(2, '0')})" : ""}',
                            style: TextStyle(
                              color: _remainingSeconds == 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFBBC0CC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    
                    // Doğrula Butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _enteredCode.length == 6 ? _verifyCode : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFC8E6C9),
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Doğrula',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Geri Git Butonu
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const LoginScreen(),
                              transitionsBuilder: (context, anim, secondaryAnim, child) {
                                return FadeTransition(opacity: anim, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32), size: 20),
                        label: const Text(
                          'Geri Git',
                          style: TextStyle(
                            color: Color(0xFF2E7D32), 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dikey ayırıcı (Artık sağ panel tam kapladığı için buna gerek yok, siliyoruz)
          
          // ── Sağ Panel: İş Makinesi Görseli (Dalgalı Kesim) ──────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FC),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: ClipPath(
                    clipper: _BlobClipper(),
                    child: Image.asset(
                      'assets/images/machinery.jpg',
                      fit: BoxFit.contain, // Kırpma olmaması için contain yapıldı
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ÖZEL NUMPAD WIDGET'LARI (LoginScreen'den Kopyalandı)
// ─────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const _NumPad({
    required this.onKey,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F5)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _NumRow(keys: const ['1', '2', '3'], onKey: onKey),
          const SizedBox(height: 8),
          _NumRow(keys: const ['4', '5', '6'], onKey: onKey),
          const SizedBox(height: 8),
          _NumRow(keys: const ['7', '8', '9'], onKey: onKey),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SpecialKey(label: 'Temizle', onTap: onClear)),
              const SizedBox(width: 8),
              Expanded(child: _NumKey(label: '0', onKey: onKey)),
              const SizedBox(width: 8),
              Expanded(child: _SpecialKey(label: '⌫ Sil', onTap: onDelete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumRow extends StatelessWidget {
  final List<String> keys;
  final ValueChanged<String> onKey;

  const _NumRow({required this.keys, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: keys
          .expand((k) => [
                Expanded(child: _NumKey(label: k, onKey: onKey)),
                if (k != keys.last) const SizedBox(width: 8),
              ])
          .toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final ValueChanged<String> onKey;

  const _NumKey({required this.label, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onKey(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE1EA)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D2E),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SpecialKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DALGALI KESİM WIDGET'I (Blob Clipper)
// ─────────────────────────────────────────────
class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    double w = size.width;
    double h = size.height;
    
    // Köşe kavis oranı
    double cornerW = w * 0.2;
    double cornerH = h * 0.2;
    
    // İçeri doğru bükülme (dalga) oranı
    double pinchW = w * 0.05;
    double pinchH = h * 0.05;
    
    // Sol Üst Köşe
    path.moveTo(0, cornerH);
    path.quadraticBezierTo(0, 0, cornerW, 0);
    
    // Üst Kenar (Hafif içeri dalgalı)
    path.quadraticBezierTo(w * 0.5, pinchH, w - cornerW, 0);
    
    // Sağ Üst Köşe
    path.quadraticBezierTo(w, 0, w, cornerH);
    
    // Sağ Kenar (Hafif içeri dalgalı)
    path.quadraticBezierTo(w - pinchW, h * 0.5, w, h - cornerH);
    
    // Sağ Alt Köşe
    path.quadraticBezierTo(w, h, w - cornerW, h);
    
    // Alt Kenar (Hafif içeri dalgalı)
    path.quadraticBezierTo(w * 0.5, h - pinchH, cornerW, h);
    
    // Sol Alt Köşe
    path.quadraticBezierTo(0, h, 0, h - cornerH);
    
    // Sol Kenar (Hafif içeri dalgalı)
    path.quadraticBezierTo(pinchW, h * 0.5, 0, cornerH);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
