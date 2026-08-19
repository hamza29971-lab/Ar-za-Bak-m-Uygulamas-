import 'package:flutter/services.dart';

/// (05XX) XXX XX XX biçiminde telefon maskesi.
class TrPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits =
        newValue.text.replaceAll(RegExp(r'\D'), '').substring(0, _len(newValue.text));
    final String formatted = formatPhone(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  int _len(String text) {
    final int digits = text.replaceAll(RegExp(r'\D'), '').length;
    return digits > 11 ? 11 : digits;
  }
}

/// Ham rakamları (05XX) XXX XX XX biçimine çevirir.
String formatPhone(String digits) {
  final String d = digits.length > 11 ? digits.substring(0, 11) : digits;
  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < d.length; i++) {
    if (i == 0) sb.write('(');
    if (i == 4) sb.write(') ');
    if (i == 7 || i == 9) sb.write(' ');
    sb.write(d[i]);
  }
  return sb.toString();
}
