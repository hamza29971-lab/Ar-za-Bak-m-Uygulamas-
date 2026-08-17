// lib/ui/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'tire_change_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // 0 = Telefon, 1 = E-posta
  int _selectedTab = 0;

  // Girilen değer
  String _inputValue = '';
  final TextEditingController _emailController = TextEditingController();

  bool get _canLogin {
    if (_selectedTab == 0) {
      // Telefon: en az 10 rakam
      return _inputValue.replaceAll(RegExp(r'\D'), '').length >= 10;
    } else {
      // E-posta: @ içermeli
      return _emailController.text.contains('@') &&
          _emailController.text.contains('.');
    }
  }

  // Numpad tuşuna basıldı
  void _onNumKey(String key) {
    setState(() {
      final digits = _inputValue.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 11) {
        _inputValue = _formatPhone(digits + key);
      }
    });
  }

  // Sil (backspace)
  void _onDelete() {
    setState(() {
      final digits = _inputValue.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        _inputValue = _formatPhone(digits.substring(0, digits.length - 1));
      }
    });
  }

  // Temizle
  void _onClear() {
    setState(() => _inputValue = '');
  }

  // Telefon numarası formatlama: 05XX XXX XX XX
  String _formatPhone(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 4) return digits;
    if (digits.length <= 7) return '${digits.substring(0, 4)} ${digits.substring(4)}';
    if (digits.length <= 9) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
  }

  void _login() {
    if (!_canLogin) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TireChangeScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Sol Panel: Login Formu ────────────────────────────────
          SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Robot Karakter
                    Image.asset(
                      'assets/images/robot_character.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Başlık
                    const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Telefon veya e-posta ile giriş yapın.\nDoğrulama kodu gönderilecektir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7B8094),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tab Bar
                    _TabBar(
                      selectedTab: _selectedTab,
                      onTabChanged: (i) {
                        setState(() {
                          _selectedTab = i;
                          _inputValue = '';
                          _emailController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // İçerik
                    if (_selectedTab == 0) ...[
                      _PhoneInput(value: _inputValue),
                      const SizedBox(height: 16),
                      _NumPad(
                        onKey: _onNumKey,
                        onDelete: _onDelete,
                        onClear: _onClear,
                      ),
                    ] else ...[
                      _EmailInput(
                        controller: _emailController,
                        onChanged: (value) => setState(() {}),
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

          // Dikey ayırıcı
          Container(width: 1, color: const Color(0xFFEEF0F5)),

          // ── Sağ Panel: Karşılama + Araç Görseli ──────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  // Hoşgeldiniz Metni
                  const Text(
                    'NUH ÇİMENTO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D2E),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'BAKIM SİSTEMİNE HOŞGELDİNİZ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Araç Görseli
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
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
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE1EA)),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF7B8094),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF7B8094),
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
class _PhoneInput extends StatelessWidget {
  final String value;
  const _PhoneInput({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telefon',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7B8094),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: value.isNotEmpty
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFDDE1EA),
              width: value.isNotEmpty ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.isEmpty ? '(05XX) XXX XX XX' : value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: value.isEmpty
                  ? const Color(0xFFBBC0CC)
                  : const Color(0xFF1A1D2E),
              letterSpacing: 1.2,
            ),
          ),
        ),
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
        const Text(
          'E-posta',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7B8094),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'ornek@email.com',
            hintStyle: const TextStyle(color: Color(0xFFBBC0CC)),
            prefixIcon: const Icon(Icons.email_outlined,
                color: Color(0xFF7B8094), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDDE1EA), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDDE1EA), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D2E),
          ),
        ),
        const SizedBox(height: 80), // E-posta sekmesinde numpad yok, boşluk
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ÖZEL NUMPAD
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
          _NumRow(keys: ['1', '2', '3'], onKey: onKey),
          const SizedBox(height: 8),
          _NumRow(keys: ['4', '5', '6'], onKey: onKey),
          const SizedBox(height: 8),
          _NumRow(keys: ['7', '8', '9'], onKey: onKey),
          const SizedBox(height: 8),
          // Son satır: Temizle | 0 | Sil
          Row(
            children: [
              Expanded(
                child: _SpecialKey(
                  label: 'Temizle',
                  onTap: onClear,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumKey(label: '0', onKey: onKey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SpecialKey(
                  label: '⌫ Sil',
                  onTap: onDelete,
                ),
              ),
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
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF2E7D32),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: canLogin ? 2 : 0,
          ),
          icon: const Icon(Icons.login_rounded, size: 20),
          label: const Text(
            'Giriş Yap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
