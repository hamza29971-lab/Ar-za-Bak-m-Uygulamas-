import re
import os

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\login_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace Snackbar with AlertDialog for error
pattern_error = re.compile(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\(errorMsg\)\),\s*\);', re.DOTALL)
replacement_error = """showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Giriş Hatası'),
              content: Text(errorMsg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );"""

if pattern_error.search(content):
    content = pattern_error.sub(lambda m: replacement_error, content)
    print("Error popup fixed")
else:
    print("Error popup NOT found")

# 2. Replace keyboardType
content = content.replace("keyboardType: TextInputType.phone,", "keyboardType: TextInputType.number,")
print("Keyboard type updated")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
