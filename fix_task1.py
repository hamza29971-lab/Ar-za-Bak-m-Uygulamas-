import os
import re

def add_confirmation(file_path, is_service_report=False):
    if not os.path.exists(file_path):
        return
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the _sendPending method or equivalent
    if not is_service_report:
        pattern = re.compile(r'(Future<void> _sendPending\([^)]+\)\s*async\s*\{)(\s*final List<PendingOperation> pending [^\n]+;)', re.DOTALL)
        replacement = r"""\1
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Emin misiniz?'),
          content: const Text('Bekleyen tüm işlemleri göndermek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF198754)),
              child: const Text('Evet, Gönder'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
\2"""
        content = pattern.sub(replacement, content, count=1)
    else:
        # In service_report_screen.dart
        pattern = re.compile(r'(Future<void> _submit\(\)\s*async\s*\{)(\s*if \(!_formKey\.currentState!\.validate\(\)\) return;)', re.DOTALL)
        replacement = r"""\1\2
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Emin misiniz?'),
          content: const Text('Servis raporunu göndermek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF198754)),
              child: const Text('Evet, Gönder'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
"""
        content = pattern.sub(replacement, content, count=1)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Added confirmation to {os.path.basename(file_path)}")

add_confirmation(r'C:\new class\nimo_ariza_bakim\lib\ui\screens\tire_change_screen.dart')
add_confirmation(r'C:\new class\nimo_ariza_bakim\lib\screens\oil_screen.dart')
add_confirmation(r'C:\new class\nimo_ariza_bakim\lib\screens\service_report_screen.dart', is_service_report=True)
