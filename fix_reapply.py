import os
import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\tire_change_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Autofocus
content = content.replace('autofocus: true,', 'autofocus: false,')

# 2. Confirmation Popup
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

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Task 1 and 2 reapplied")
