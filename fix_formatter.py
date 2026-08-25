import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\login_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(
    r'TextEditingValue formatEditUpdate\(.*?\)\s*\{.*?final String formatted = _formatPhone\(digits\);\s*return TextEditingValue\(\s*text: formatted,\s*selection: TextSelection\.collapsed\(offset: formatted\.length\),\s*\);\s*\}',
    re.DOTALL
)

replacement = """TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
    ) {
      String digits = newValue.text.replaceAll(RegExp(r'\\D'), '');
      
      // Silme (Backspace) kilitlenmesi cozumu
      if (oldValue.text.length > newValue.text.length && 
          oldValue.text.replaceAll(RegExp(r'\\D'), '') == digits) {
        if (digits.isNotEmpty) {
          digits = digits.substring(0, digits.length - 1);
        }
      }
      
      if (digits.length > 11) {
        return oldValue; // 11 haneden fazla girmesin
      }
      
      final String formatted = _formatPhone(digits);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }"""

if pattern.search(content):
    # Using lambda for replacement to avoid backslash escaping issues in re.sub
    content = pattern.sub(lambda m: replacement, content)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done")
else:
    print("Not found")
