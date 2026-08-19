/// Telefon numarası normalize etme ve maskeleme yardımcıları.
library;

/// Girilen numarayı `905325554062` biçimine çevirir.
///
/// `0532 555 40 62`, `+90 532 555 40 62`, `532 555 40 62` gibi yazımların
/// hepsi aynı sonucu verir. Tanınmayan biçimlerde rakamlar olduğu gibi döner;
/// doğrulama backend tarafında da yapılacaktır.
String normalizePhone(String input) {
  String digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 10) return '90$digits'; // 5325554062
  if (digits.length == 11 && digits.startsWith('0')) {
    return '90${digits.substring(1)}'; // 05325554062
  }
  if (digits.length == 12 && digits.startsWith('90')) return digits;
  return digits;
}

/// Ekranda gösterim için maskeler: `******* *062`
String maskPhone(String input) {
  final String digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 3) return '*******';
  return '******* *${digits.substring(digits.length - 3)}';
}

/// E-posta maskesi: `sa*******@hotmail.com`
String maskEmail(String input) {
  final List<String> parts = input.split('@');
  if (parts.length != 2) return input;
  final String name = parts.first;
  final String masked =
      name.length <= 2 ? '**' : '${name.substring(0, 2)}${'*' * (name.length - 2)}';
  return '$masked@${parts[1]}';
}
