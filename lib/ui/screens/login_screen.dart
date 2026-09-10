// lib/ui/screens/login_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/numeric_keypad.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../screens/shell_screen.dart';
import 'otp_screen.dart';
import '../../services/auth_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.nimo.nimo_arizabakim/sms');

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideRightPanelAnim;
  late final Animation<Offset> _slideLeftPanelAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideRightPanelAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _slideLeftPanelAnim = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    
    _animController.forward();
  }

  // 0 = Telefon, 1 = E-posta
  int _selectedTab = 0;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool get _canLogin {
    final passwordFilled = _passwordController.text.isNotEmpty;
    if (_selectedTab == 0) {
      // Telefon: en az 10 rakam
      return _phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 10 && passwordFilled;
    } else {
      // E-posta: @ içermeli
      return _emailController.text.contains('@') &&
          _emailController.text.contains('.') && passwordFilled;
    }
  }

  Future<void> _login() async {
    if (!_canLogin) return;

    final String loginId = _selectedTab == 0 
        ? _phoneController.text.replaceAll(RegExp(r'\D'), '') 
        : _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (AuthApiService.useRealApi) {
      // Gerçek API ile Login
      try {
        final otpRequestId = await AuthApiService.loginWithPhone(loginId, password);
        
        if (!mounted) return;
        
        if (otpRequestId != null) {
          // OTP Ekranına yönlendir
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  OtpScreen(phoneNumber: loginId, correctCode: '', otpRequestId: otpRequestId, password: password),
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
        showDialog(
            context: context,
            // Giriş ekranı hep açık temada olduğu için diyalogu da açık
            // temaya sabitliyoruz; aksi halde uygulama koyu moddayken
            // pencere koyu gelirdi.
            builder: (context) => Theme(
              data: AppTheme.light(),
              child: AlertDialog(
                title: const Text('Giriş Hatası'),
                content: Text(errorMsg),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            ),
          );
      }
      return;
    }

    // --- Eski Bypass/SMS Mantığı (useRealApi = false) ---
    if (_selectedTab == 0) {
      // Telefon ile giriş
      final cleanPhone = loginId;
      
      // Rastgele 6 haneli kod üret
      final otp = (100000 + Random().nextInt(900000)).toString();
      final message = 'DTSPRO Giriş doğrulama kodunuz: $otp B021';

      // Bypass şifresi (SMS çalışmadığında kullanılır)
      const String bypassCode = '000000';
      String correctCode = bypassCode;

      try {
        // SMS İzni İste (Sadece Android'de)
        if (Theme.of(context).platform == TargetPlatform.android) {
          var status = await Permission.sms.request();
          if (status.isGranted) {
            await platform.invokeMethod('sendSms', {
              'phone': cleanPhone,
              'message': message,
            });
            correctCode = otp; // SMS gittiyse gerçek kod
          } else {
            // SMS izni yok: bilgi ver ama OTP ekranına geç
            if (status.isPermanentlyDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SMS izni kapalı. Giriş için bypass şifresi kullanın.'),
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SMS gönderilemedi. Bypass şifresi ile giriş yapabilirsiniz.')),
              );
            }
            // Bypass şifresiyle OTP ekranına yönlendir
          }
        } else {
          // Windows veya diğer platformlarda test ederken SMS gitmez
          debugPrint('TEST MODU (SMS Gönderilmedi): $message');
        }
      } catch (e) {
        debugPrint('SMS Gönderme Hatası: $e');
        // SMS hata verse de OTP'ye geç (bypass şifresiyle)
      }

      if (!mounted) return;

      // OTP ekranına yönlendir (SMS gittiyse gerçek kod, gitmediyse bypass: 1234)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpScreen(phoneNumber: cleanPhone, correctCode: correctCode),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // E-posta ile giriş → ShellScreen'e gönder
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
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Giriş ekranı, uygulamanın tema tercihi ne olursa olsun her zaman açık
    // temada gösterilir. Builder, alt ağacın bu yeni temayı görmesini sağlar.
    return Theme(
      data: AppTheme.light(),
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: context.authBg,
      body: Row(
        children: [
          // ── Sol Panel: Login Formu ────────────────────────────────
          SlideTransition(
            position: _slideLeftPanelAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SizedBox(
                // Form sütunu ekranın yaklaşık %42'sini kaplar; dar ekranlarda
                // eski genişliğin altına inmez, çok geniş ekranlarda taşmaz.
                width: (MediaQuery.sizeOf(context).width * 0.42)
                    .clamp(460.0, 760.0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Robot Karakter
                        Image.asset(
                          'assets/images/robot_yenii.png',
                          height: 124,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 18),

                        // Başlık
                        Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: context.authTitle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Telefon veya e-posta ile giriş yapın.\nDoğrulama kodu gönderilecektir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.authMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Tab Bar
                        _TabBar(
                          selectedTab: _selectedTab,
                          onTabChanged: (i) {
                            setState(() {
                              _selectedTab = i;
                              _phoneController.clear();
                              _emailController.clear();
                              _passwordController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // İçerik
                        if (_selectedTab == 0) ...[
                          _PhoneInput(
                            controller: _phoneController,
                            onChanged: (val) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _PasswordInput(
                            controller: _passwordController,
                            onChanged: (val) => setState(() {}),
                            onSubmitted: _login,
                          ),
                        ] else ...[
                          _EmailInput(
                            controller: _emailController,
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _PasswordInput(
                            controller: _passwordController,
                            onChanged: (val) => setState(() {}),
                            onSubmitted: _login,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Giriş Yap Butonu
                        _LoginButton(
                          canLogin: _canLogin,
                          onLogin: _login,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dikey ayırıcı
          Container(width: 1, color: context.authDivider),

          // ── Sağ Panel: Karşılama + Araç Görseli ──────────────────
          Expanded(
            child: SlideTransition(
              position: _slideRightPanelAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/çimnak_logo.png',
                        height: 110,
                      ),
                      const SizedBox(height: 22),
                      // Sadece yeni başlık yazısı
                      Text(
                        'Nuh Intelligent Mining Operations',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: context.authTitle,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Büyütülmüş Hoşgeldiniz Yazısı
                      Text(
                        'ARIZA VE BAKIM SİSTEMİNE HOŞGELDİNİZ',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: context.authGreen,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 80),
                          child: Image.asset(
                            'assets/images/truck_damper.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ],
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
// TAB BAR
// ─────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _TabBar({required this.selectedTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.authSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.authBorder),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Telefon',
            icon: Icons.phone_outlined,
            isSelected: selectedTab == 0,
            onTap: () => onTabChanged(0),
            isFirst: true,
          ),
          _TabItem(
            label: 'E-posta',
            icon: Icons.email_outlined,
            isSelected: selectedTab == 1,
            onTap: () => onTabChanged(1),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? context.authGreenFill : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : context.authMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : context.authMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TELEFON GİRİŞ ALANI
// ─────────────────────────────────────────────
class _PhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PhoneInput({required this.controller, required this.onChanged});

  @override
  State<_PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<_PhoneInput> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Panel yalnizca alan odaktayken durur; baska bir alana gecilince
    // kendiliginden kapanir.
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
    if (!_focus.hasFocus) return;
    // Panel alanin altinda aciliyor; form kaydirilabilir oldugu icin
    // ikisini birden gorunur alana getir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Alandaki ham rakamlar.
  String get _digits => widget.controller.text.replaceAll(RegExp(r'\D'), '');

  void _setDigits(String digits) {
    final String formatted = formatPhoneDigits(digits);
    // Alan readOnly oldugu icin inputFormatters calismaz; bicimlendirme
    // burada elle yapilir.
    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    widget.onChanged(formatted);
  }

  void _appendDigit(String digit) {
    final String digits = _digits;
    if (digits.length >= kPhoneMaxDigits) return;
    _setDigits(digits + digit);
  }

  void _backspace() {
    final String digits = _digits;
    if (digits.isEmpty) return;
    _setDigits(digits.substring(0, digits.length - 1));
  }

  void _clear() {
    if (_digits.isEmpty) return;
    _setDigits('');
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = widget.controller;
    final bool hasValue = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Telefon',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.authMuted,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: _focus,
          // Tabletin sistem klavyesi ACILMAZ: alan salt okunur, rakamlar
          // asagidaki uygulama ici panelden girilir. Imlec yine gorunur.
          readOnly: true,
          showCursor: true,
          onTap: () => _focus.requestFocus(),
          // Masaustu platformlarda TextField varsayilan olarak alanin
          // DISINA her tiklamada odagi birakir. Sayi paneli alanin
          // disinda ayri bir widget oldugu icin bu varsayilan, panele
          // her dokunuldugunda odagi (ve paneli) aninda kapatiyordu.
          onTapOutside: (PointerDownEvent event) {},
          decoration: InputDecoration(
            hintText: '(05XX) XXX XX XX',
            hintStyle: TextStyle(color: context.authHint),
            prefixIcon: Icon(Icons.phone_outlined,
                color: context.authMuted, size: 24),
            filled: true,
            fillColor: context.authField,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasValue ? context.authGreen : context.authBorder,
                width: hasValue ? 2 : 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasValue ? context.authGreen : context.authBorder,
                width: hasValue ? 2 : 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.authGreen, width: 2),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
          ),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: context.authTitle,
            letterSpacing: 1.2,
          ),
        ),
        // Sayi paneli yalnizca alan odaktayken gorunur.
        if (_focus.hasFocus) ...<Widget>[
          const SizedBox(height: 14),
          NumericKeypad(
            stretch: true,
            keyHeight: 54,
            accent: AppColors.brand,
            doneLabel: 'Tamam',
            onDigit: _appendDigit,
            onBackspace: _backspace,
            onClear: _clear,
            onDone: _focus.unfocus,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// E-POSTA GİRİŞ ALANI
// ─────────────────────────────────────────────
class _EmailInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _EmailInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E-posta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.authMuted,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.email],
          decoration: InputDecoration(
            hintText: 'ornek@email.com',
            hintStyle: TextStyle(color: context.authHint),
            prefixIcon: Icon(Icons.email_outlined,
                color: context.authMuted, size: 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.authBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.authBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: context.authGreen, width: 2),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
          ),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: context.authTitle,
          ),
        ),
      ],
    );
  }
}





// ─────────────────────────────────────────────
// GİRİŞ BUTONU
// ─────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  final bool canLogin;
  final VoidCallback onLogin;

  const _LoginButton({required this.canLogin, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: canLogin ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canLogin ? onLogin : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.authGreenFill,
            foregroundColor: Colors.white,
            disabledBackgroundColor: context.authGreenFill,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: canLogin ? 2 : 0,
          ),
          icon: const Icon(Icons.login_rounded, size: 24),
          label: const Text(
            'Giriş Yap',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ŞİFRE GİRİŞ ALANI
// ─────────────────────────────────────────────
class _PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Klavyedeki "bitti" tusuna basildiginda calisir.
  final VoidCallback? onSubmitted;

  const _PasswordInput({
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = widget.controller.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şifre',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.authMuted,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.password],
          // Tablette klavyedeki "bitti" tusu dogrudan girisi baslatir.
          onSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: context.authHint),
            prefixIcon: Icon(Icons.lock_outline,
                color: context.authMuted, size: 24),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: context.authMuted,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            filled: true,
            fillColor: context.authField,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasValue ? context.authGreen : context.authBorder,
                width: hasValue ? 2 : 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasValue ? context.authGreen : context.authBorder,
                width: hasValue ? 2 : 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.authGreen, width: 2),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
          ),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: context.authTitle,
            letterSpacing: _obscureText ? 2.0 : 1.0,
          ),
        ),
      ],
    );
  }
}

/// Ham rakamlari "(05XX) XXX XX XX" bicimine cevirir.
///
/// Telefon alani salt okunurdur; rakamlar uygulama ici sayi klavyesinden
/// gelir ve bicimlendirme burada yapilir.
String formatPhoneDigits(String digits) {
  if (digits.isEmpty) return '';
  if (digits.length <= 4) {
    return digits.length == 4 ? '($digits) ' : '($digits';
  }
  if (digits.length <= 7) {
    return '(${digits.substring(0, 4)}) ${digits.substring(4)}';
  }
  if (digits.length <= 9) {
    return '(${digits.substring(0, 4)}) ${digits.substring(4, 7)} ${digits.substring(7)}';
  }
  return '(${digits.substring(0, 4)}) ${digits.substring(4, 7)} '
      '${digits.substring(7, 9)} ${digits.substring(9)}';
}

/// Telefon alanina girilebilecek en fazla hane.
const int kPhoneMaxDigits = 11;
